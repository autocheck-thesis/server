import "phoenix_html";
import LiveSocket from "phoenix_live_view";

import { create_code_editor } from "./code-editor";
import { scroll_log } from "./log-scroller";

import "../css/app.css";

const form = document.getElementById("configuration-form");
const code_editor = document.getElementById("code-editor");

const code_validation_output = document.getElementById("code_validation_output");

create_code_editor(code_editor, form, form.elements["dsl"], code_validation_output, 1000);

const log = document.querySelector("#log code");
scroll_log(log);

const is_in_iframe = window !== window.parent;

if (is_in_iframe) {
  document.body.classList.add("iframe");
}

let liveSocket = new LiveSocket("/live");
liveSocket.connect();
