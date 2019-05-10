import "phoenix_html";
import LiveSocket from "phoenix_live_view";

import { create_code_editor } from "./code-editor";
import { scroll_log } from "./log-scroller";

import "../css/app.css";

create_code_editor(document.getElementById("code-editor"));
scroll_log(document.querySelector("#log code"));

const is_in_iframe = window !== window.parent;

if (is_in_iframe) {
  document.body.classList.add("iframe");
}

let liveSocket = new LiveSocket("/live");
liveSocket.connect();
