// The feedback button: a custom element in a shadow root, so neither the host's CSS nor its
// JavaScript bundle is involved. Served as is by the host's asset pipeline.

const MAX_WIDTH = 2560
const MAX_ERRORS = 10

// Kept at module level: Turbo replaces the element on every visit, the draft survives it.
const draft = { open: false, kind: "bug", description: "", screenshot: null }
const errors = []

function remember(message) {
  errors.push(`${new Date().toISOString()} ${message}`.slice(0, 500))
  if (errors.length > MAX_ERRORS) errors.shift()
}

window.addEventListener("error", (event) => remember(`${event.message} (${event.filename}:${event.lineno})`))
window.addEventListener("unhandledrejection", (event) => remember(`Unhandled rejection: ${event.reason}`))

const STYLE = `
  :host { all: initial; font: 13px/1.4 system-ui, -apple-system, "Segoe UI", sans-serif; color: #18181b;
          --border: #d4d4d8; --muted: #71717a; --surface: #fff; --soft: #f4f4f5; --text: #18181b; }
  :host([hidden]) { display: none !important; }
  * { box-sizing: border-box; font: inherit; }
  [hidden] { display: none !important; }
  .toggle { position: fixed; right: 16px; bottom: 16px; z-index: 2147483000; padding: 6px 12px;
            border: 1px solid var(--border); border-radius: 6px; background: var(--surface); color: var(--text);
            box-shadow: 0 1px 2px rgb(0 0 0 / .08); cursor: pointer; }
  .toggle:hover { background: var(--soft); }
  .panel { position: fixed; right: 16px; bottom: 56px; z-index: 2147483001; width: min(380px, calc(100vw - 32px));
           max-height: calc(100vh - 72px); overflow: auto; padding: 14px; border: 1px solid var(--border);
           border-radius: 8px; background: var(--surface); color: var(--text); box-shadow: 0 8px 24px rgb(0 0 0 / .12); }
  header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; }
  h2 { margin: 0; font-weight: 600; font-size: 14px; }
  button { cursor: pointer; }
  .close { border: 0; background: none; color: var(--muted); font-size: 18px; line-height: 1; padding: 2px 4px; }
  fieldset { border: 0; padding: 0; margin: 0 0 10px; display: flex; flex-direction: column; gap: 4px; }
  label.kind { display: flex; align-items: center; gap: 6px; }
  label.kind input { margin: 0; }
  textarea { width: 100%; min-height: 110px; resize: vertical; padding: 8px; border: 1px solid var(--border);
             border-radius: 6px; background: var(--surface); color: var(--text); }
  textarea:focus { outline: 2px solid #3f3f46; outline-offset: -1px; }
  .hint { margin: 4px 0 10px; color: var(--muted); font-size: 12px; }
  .shot { border: 1px dashed var(--border); border-radius: 6px; padding: 8px; margin-bottom: 12px; }
  .shot.over { background: var(--soft); }
  .shot-actions { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
  .shot img { display: block; max-width: 100%; max-height: 180px; margin: 0 auto 6px; border: 1px solid var(--border); }
  .secondary { padding: 4px 8px; border: 1px solid var(--border); border-radius: 6px; background: var(--surface); color: var(--text); }
  .secondary:hover { background: var(--soft); }
  .footer { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
  .message { color: var(--muted); font-size: 12px; }
  .message.error { color: #b91c1c; }
  .submit { padding: 6px 14px; border: 1px solid #18181b; border-radius: 6px; background: #18181b; color: #fff; }
  .submit:disabled { opacity: .5; cursor: default; }
  .done p { margin: 0 0 12px; }
`

class TicketWidget extends HTMLElement {
  connectedCallback() {
    if (this.shadowRoot) return

    this.strings = JSON.parse(this.dataset.strings || "{}")
    this.attachShadow({ mode: "open" })
    this.render()
    this.restore()
  }

  disconnectedCallback() {
    document.removeEventListener("keydown", this.onKeydown)
    document.removeEventListener("paste", this.onPaste)
  }

  t(key) {
    return key.split(".").reduce((value, part) => value?.[part], this.strings) ?? key
  }

  render() {
    const kinds = ["bug", "idea", "question"].map((kind) => `
      <label class="kind"><input type="radio" name="kind" value="${kind}"> ${this.escape(this.t(`kinds.${kind}`))}</label>`).join("")

    this.shadowRoot.innerHTML = `
      <style>${STYLE}</style>
      <button type="button" class="toggle" part="toggle" aria-expanded="false">${this.escape(this.t("button"))}</button>
      <section class="panel" role="dialog" aria-label="${this.escape(this.t("title"))}" hidden>
        <header>
          <h2>${this.escape(this.t("title"))}</h2>
          <button type="button" class="close" aria-label="${this.escape(this.t("close"))}">×</button>
        </header>
        <form class="form" novalidate>
          <fieldset>${kinds}</fieldset>
          <textarea name="description" required placeholder="${this.escape(this.t("description"))}"></textarea>
          <p class="hint">${this.escape(this.t("description_hint"))}</p>
          <div class="shot">
            <img alt="" hidden>
            <div class="shot-actions">
              <button type="button" class="secondary capture">${this.escape(this.t("capture"))}</button>
              <button type="button" class="secondary choose">${this.escape(this.t("choose"))}</button>
              <button type="button" class="secondary remove" hidden>${this.escape(this.t("remove"))}</button>
              <span class="message paste-hint">${this.escape(this.t("paste_hint"))}</span>
            </div>
            <input type="file" accept="image/png,image/jpeg,image/webp" hidden>
          </div>
          <div class="footer">
            <span class="message status" role="status"></span>
            <button type="submit" class="submit">${this.escape(this.t("submit"))}</button>
          </div>
        </form>
        <div class="done" hidden>
          <p>${this.escape(this.t("sent"))}</p>
          <div class="footer">
            <button type="button" class="secondary another">${this.escape(this.t("another"))}</button>
            <button type="button" class="secondary close-done">${this.escape(this.t("close"))}</button>
          </div>
        </div>
      </section>`

    const $ = (selector) => this.shadowRoot.querySelector(selector)
    this.els = {
      toggle: $(".toggle"), panel: $(".panel"), form: $(".form"), done: $(".done"),
      description: $("textarea"), image: $(".shot img"), shot: $(".shot"), file: $("input[type=file]"),
      capture: $(".capture"), remove: $(".remove"), status: $(".status"), submit: $(".submit")
    }

    if (!navigator.mediaDevices?.getDisplayMedia) this.els.capture.hidden = true

    this.els.toggle.addEventListener("click", () => this.setOpen(!draft.open))
    $(".close").addEventListener("click", () => this.setOpen(false))
    $(".close-done").addEventListener("click", () => { this.reset(); this.setOpen(false) })
    $(".another").addEventListener("click", () => this.reset())
    $(".choose").addEventListener("click", () => this.els.file.click())
    this.els.capture.addEventListener("click", () => this.capture())
    this.els.remove.addEventListener("click", () => this.setScreenshot(null))
    this.els.file.addEventListener("change", () => this.takeFile(this.els.file.files[0]))
    this.els.description.addEventListener("input", () => { draft.description = this.els.description.value })
    this.shadowRoot.querySelectorAll("input[name=kind]").forEach((input) =>
      input.addEventListener("change", () => { draft.kind = input.value }))
    this.els.form.addEventListener("submit", (event) => { event.preventDefault(); this.submit() })

    this.els.shot.addEventListener("dragover", (event) => { event.preventDefault(); this.els.shot.classList.add("over") })
    this.els.shot.addEventListener("dragleave", () => this.els.shot.classList.remove("over"))
    this.els.shot.addEventListener("drop", (event) => {
      event.preventDefault()
      this.els.shot.classList.remove("over")
      this.takeFile(event.dataTransfer.files[0])
    })

    this.onKeydown = (event) => {
      if (!draft.open) return
      if (event.key === "Escape") this.setOpen(false)
      if (event.key === "Enter" && (event.metaKey || event.ctrlKey) && !this.els.form.hidden) this.submit()
    }
    this.onPaste = (event) => {
      if (!draft.open) return
      const file = [...(event.clipboardData?.files || [])].find((item) => item.type.startsWith("image/"))
      if (file) { event.preventDefault(); this.takeFile(file) }
    }
    document.addEventListener("keydown", this.onKeydown)
    document.addEventListener("paste", this.onPaste)
  }

  restore() {
    this.els.description.value = draft.description
    this.shadowRoot.querySelector(`input[value=${draft.kind}]`).checked = true
    this.setScreenshot(draft.screenshot)
    this.setOpen(draft.open, { focus: false })
  }

  setOpen(open, { focus = true } = {}) {
    draft.open = open
    this.els.panel.hidden = !open
    this.els.toggle.setAttribute("aria-expanded", String(open))
    if (open && focus) this.els.description.focus()
  }

  setScreenshot(blob) {
    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)
    this.previewUrl = null
    draft.screenshot = blob

    if (blob) {
      this.previewUrl = URL.createObjectURL(blob)
      this.els.image.src = this.previewUrl
    } else {
      this.els.image.removeAttribute("src")
      this.els.file.value = ""
    }
    this.els.image.hidden = !blob
    this.els.remove.hidden = !blob
  }

  async takeFile(file) {
    if (!file || !file.type.startsWith("image/")) return
    try {
      const bitmap = await createImageBitmap(file)
      this.setScreenshot(await this.encode(bitmap, bitmap.width, bitmap.height))
      bitmap.close()
      this.showStatus("")
    } catch {
      this.showStatus(this.t("capture_failed"), true)
    }
  }

  // The current tab, picked in the browser's own dialog. The panel steps aside while it is taken.
  async capture() {
    let stream
    this.hidden = true
    try {
      stream = await navigator.mediaDevices.getDisplayMedia({
        video: { displaySurface: "browser" }, audio: false, preferCurrentTab: true, selfBrowserSurface: "include"
      })
      const video = document.createElement("video")
      video.muted = true
      video.srcObject = stream
      await video.play()
      // Let the browser's sharing prompt leave the picture. A still page sends no new frame, hence the timeout.
      await new Promise((resolve) => setTimeout(resolve, 400))
      await new Promise((resolve) => { video.requestVideoFrameCallback?.(resolve); setTimeout(resolve, 300) })
      if (!video.videoWidth) throw new Error("no frame")
      this.setScreenshot(await this.encode(video, video.videoWidth, video.videoHeight))
      this.showStatus("")
    } catch (error) {
      if (error?.name !== "NotAllowedError") this.showStatus(this.t("capture_failed"), true)
    } finally {
      stream?.getTracks().forEach((track) => track.stop())
      this.hidden = false
    }
  }

  async encode(source, width, height) {
    const scale = Math.min(1, MAX_WIDTH / width)
    const canvas = document.createElement("canvas")
    canvas.width = Math.round(width * scale)
    canvas.height = Math.round(height * scale)
    canvas.getContext("2d").drawImage(source, 0, 0, canvas.width, canvas.height)
    return new Promise((resolve, reject) =>
      canvas.toBlob((blob) => (blob ? resolve(blob) : reject(new Error("encode"))), "image/webp", 0.9))
  }

  async submit() {
    if (!this.els.description.value.trim()) {
      this.els.description.focus()
      return
    }

    const body = new FormData()
    body.append("kind", draft.kind)
    body.append("description", this.els.description.value)
    body.append("page_url", location.href)
    body.append("page_title", document.title)
    if (this.dataset.requestId) body.append("page_request_id", this.dataset.requestId)
    body.append("browser[viewport]", `${innerWidth}×${innerHeight}`)
    body.append("browser[screen]", `${screen.width}×${screen.height} @${devicePixelRatio}x`)
    body.append("browser[language]", navigator.language)
    body.append("browser[timezone]", Intl.DateTimeFormat().resolvedOptions().timeZone)
    errors.forEach((error) => body.append("errors[]", error))
    if (draft.screenshot) body.append("screenshot", draft.screenshot, `screenshot.${draft.screenshot.type.split("/")[1]}`)

    this.els.submit.disabled = true
    this.showStatus(this.t("sending"))
    try {
      const response = await fetch(this.dataset.endpoint, {
        method: "POST",
        body,
        credentials: "same-origin",
        headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content || "", Accept: "application/json" }
      })
      if (response.ok) {
        this.els.form.hidden = true
        this.els.done.hidden = false
        this.showStatus("")
      } else if (response.status === 401 || response.status === 422 && !(await response.clone().json().catch(() => null))) {
        this.showStatus(this.t("signed_out"), true)
      } else if (response.status === 413) {
        this.showStatus(this.t("image_too_large"), true)
      } else {
        this.showStatus(this.t("failed"), true)
      }
    } catch {
      this.showStatus(this.t("failed"), true)
    } finally {
      this.els.submit.disabled = false
    }
  }

  reset() {
    draft.kind = "bug"
    draft.description = ""
    this.setScreenshot(null)
    this.els.form.hidden = false
    this.els.done.hidden = true
    this.restore()
  }

  showStatus(text, error = false) {
    this.els.status.textContent = text
    this.els.status.classList.toggle("error", error)
  }

  escape(text) {
    return String(text).replace(/[&<>"']/g, (char) => `&#${char.charCodeAt(0)};`)
  }
}

if (!customElements.get("ticket-widget")) customElements.define("ticket-widget", TicketWidget)
