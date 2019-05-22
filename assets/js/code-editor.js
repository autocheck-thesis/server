function debounce(func, wait, immediate) {
  var timeout;
  return function() {
    var context = this,
      args = arguments;
    var later = function() {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
}

export function create_code_editor(target, form, input, code_validation_output, debounce_timeout = 2000) {
  if (target) {
    (async function() {
      const monaco = await import(/* webpackChunkName: "editor" */ "monaco-editor/esm/vs/editor/editor.api.js");
      // await import("monaco-editor/esm/vs/editor/browser/controller/coreCommands.js");

      const { registerRulesForLanguage } = await import(/* webpackChunkName: "ace-tokener" */ "monaco-ace-tokenizer");
      const { default: ElixirHighlightRules } = await import(
        /* webpackChunkName: "ace-tokener-elixir" */

        "monaco-ace-tokenizer/lib/ace/definitions/elixir"
      );

      monaco.languages.register({ id: "elixir" });
      registerRulesForLanguage("elixir", new ElixirHighlightRules());

      const editor = monaco.editor.create(target, {
        value: input.value,
        language: "elixir",
        minimap: {
          enabled: false
        },
        scrollBeyondLastLine: false
      });

      function createErrorMarker({ line, description, token, description_suffix }) {
        const message = description + token;
        return {
          startLineNumber: line,
          endLineNumber: line,
          startColumn: token
            ? editor
                .getModel()
                .getLineContent(line)
                .indexOf(token) + 1
            : undefined,
          endColumn: 1000,
          message: message,
          severity: monaco.MarkerSeverity.Error
        };
      }

      function showLoadingMessage() {
        const template = document.getElementById("code_validation_template");

        const message = document.importNode(template.content, true);
        const container = message.querySelector(".message");
        // container.classList.add("error");
        const icon = container.querySelector(".icon");
        icon.classList.add("notched", "circle", "loading");
        const state = container.querySelector(".state");
        state.textContent = "Validating";
        const list = container.querySelector(".list");

        list.innerHTML = "<li>Please wait...</li>";

        const output = document.getElementById("code_validation_output");

        output.innerHTML = "";
        output.appendChild(message);
      }

      function showErrorMessage(errors) {
        const template = document.getElementById("code_validation_template");

        const message = document.importNode(template.content, true);
        const container = message.querySelector(".message");
        container.classList.add("error");
        const icon = container.querySelector(".icon");
        icon.classList.add("warning", "sign");
        const state = container.querySelector(".state");
        state.textContent = "Invalid";
        const list = container.querySelector(".list");

        list.innerHTML = errors
          .map(
            ({ line, description, token, description_suffix }) =>
              `<li>Line ${line}: ${description}${token}. ${description_suffix}</li>`
          )
          .join("");

        const output = document.getElementById("code_validation_output");

        output.innerHTML = "";
        output.appendChild(message);
      }

      function showSuccessMessage() {
        const template = document.getElementById("code_validation_template");

        const message = document.importNode(template.content, true);
        const container = message.querySelector(".message");
        container.classList.add("success");
        const icon = container.querySelector(".icon");
        icon.classList.add("check");
        const state = container.querySelector(".state");
        state.textContent = "Valid";
        const list = container.querySelector(".list");

        list.innerHTML = "<li>Everything looks good</li>";

        const output = document.getElementById("code_validation_output");

        output.innerHTML = "";
        output.appendChild(message);
      }

      const validate_configuration = debounce(() => {
        const form_data = new FormData();
        form_data.append("configuration", editor.getValue());
        showLoadingMessage();
        fetch("/assignment/validate_configuration", {
          method: "POST",
          body: form_data,
          headers: { Accept: "application/json" }
        })
          .then(res => res.json())
          .then(json => {
            if (json.errors) {
              const markers = json.errors.map(error => createErrorMarker(error));
              monaco.editor.setModelMarkers(editor.getModel(), "errors", markers);
              showErrorMessage(json.errors);
            } else {
              monaco.editor.setModelMarkers(editor.getModel(), "errors", []);
              showSuccessMessage();
            }
          });
      }, debounce_timeout);

      showLoadingMessage();
      validate_configuration();
      editor.onDidChangeModelContent(e => validate_configuration());

      form.addEventListener("submit", e => {
        input.value = editor.getValue();
        // console.log(input.value, code_editor.innerText);
      });
    })();
  }
}
