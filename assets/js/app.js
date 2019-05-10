import "phoenix_html";
import LiveSocket from "phoenix_live_view";

import { create_code_editor } from "./code-editor";
import { scroll_log } from "./log-scroller";

import "../css/app.css";

const form = document.getElementById("configuration-form");
const code_editor = document.getElementById("code-editor");

const code_validation_output = document.getElementById("code_validation_output");
const configuration_valid_icon_class = "check";
const configuration_invalid_icon_class = "exclamation";
const configuration_default_text = code_validation_output.querySelector(".text").innerText;

create_code_editor(
  code_editor,
  form,
  form.elements["dsl"],
  (status, json) => {
    if (status === 200) {
      code_validation_output.querySelector(".text").innerText = configuration_default_text;
      code_validation_output.querySelector(".text").classList.add("hidden");
      code_validation_output.querySelector(".icon").classList.add(configuration_valid_icon_class);
      code_validation_output.querySelector(".icon").classList.remove(configuration_invalid_icon_class);
    } else {
      code_validation_output.querySelector(".text").innerText = "Invalid configuration: " + json.error;
      code_validation_output.querySelector(".icon").classList.add(configuration_invalid_icon_class);
      code_validation_output.querySelector(".icon").classList.remove(configuration_valid_icon_class);
    }
  },
  1000
);

const log = document.querySelector("#log code");
scroll_log(log);

const is_in_iframe = window !== window.parent;

if (is_in_iframe) {
  document.body.classList.add("iframe");
}

let liveSocket = new LiveSocket("/live");
liveSocket.connect();
