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

export function create_code_editor(target, form, input, validation_callback = function() {}, debounce_timeout = 2000) {
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

      const validate_configuration = debounce(() => {
        const form_data = new FormData();
        form_data.append("configuration", editor.getValue());
        fetch("/assignment/validate_configuration", {
          method: "POST",
          body: form_data,
          headers: { Accept: "application/json" }
        })
          .then(res => Promise.all([res.status, res.json()]))
          .then(([status, json]) => validation_callback(status, json));
      }, debounce_timeout);

      editor.onDidChangeModelContent(e => validate_configuration());

      form.addEventListener("submit", e => {
        input.value = editor.getValue();
        // console.log(input.value, code_editor.innerText);
      });
    })();
  }
}
