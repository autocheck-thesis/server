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

      const configuration_valid_icon_class = "check";
      const configuration_invalid_icon_class = "exclamation";
      const configuration_default_text = code_validation_output.querySelector(".text").innerText;

      function createErrorMarker({ line, description, token }) {
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

      const validate_configuration = debounce(() => {
        const form_data = new FormData();
        form_data.append("configuration", editor.getValue());
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

              const output_text = json.errors
                .map(({ line, description, token }) => `Line ${line}: ${description}${token}`)
                .join("\n");
              code_validation_output.querySelector(".text").innerText = output_text;
              code_validation_output.querySelector(".icon").classList.add(configuration_invalid_icon_class);
              code_validation_output.querySelector(".icon").classList.remove(configuration_valid_icon_class);
            } else {
              monaco.editor.setModelMarkers(editor.getModel(), "errors", []);
              code_validation_output.querySelector(".text").innerText = configuration_default_text;
              code_validation_output.querySelector(".text").classList.add("hidden");
              code_validation_output.querySelector(".icon").classList.add(configuration_valid_icon_class);
              code_validation_output.querySelector(".icon").classList.remove(configuration_invalid_icon_class);
            }
          });
      }, debounce_timeout);

      editor.onDidChangeModelContent(e => validate_configuration());

      form.addEventListener("submit", e => {
        input.value = editor.getValue();
        // console.log(input.value, code_editor.innerText);
      });
    })();
  }
}
