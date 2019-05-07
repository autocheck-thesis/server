const post_form = document.getElementById("post_form");
const lti_form = document.getElementById("lti_form");
const iframe = document.getElementById("target");
const placeholder = document.getElementById("placeholder");
const form_wrapper = document.getElementById("form-wrapper");
const roles = lti_form.querySelector("select[name='roles']");
const ext_roles = lti_form.querySelector("select[name='ext_roles']");
const collapse = document.getElementById("collapse");
const expand = document.getElementById("expand");
const newtab = document.getElementById("newtab");

// Add form expand and collapse toggle buttons
collapse.addEventListener("click", () => form_wrapper.classList.add("collapsed"));

expand.addEventListener("click", () => form_wrapper.classList.remove("collapsed"));

newtab.addEventListener("change", e => {
  if (e.target.checked) {
    lti_form.setAttribute("target", "_blank");
  } else {
    lti_form.setAttribute("target", "target");
  }
});

// Sync `roles` with `ext_roles`
roles.addEventListener("change", () => (ext_roles.selectedIndex = roles.selectedIndex));

lti_form.addEventListener("submit", () => {
  if (lti_form.getAttribute("target") == "target") {
    // Show our iframe
    placeholder.classList.add("hidden");
    iframe.classList.remove("hidden");
  }

  // Remove prior oauth_signature element from the form
  const oauthElement = lti_form.querySelector("input[name='oauth_signature']");
  if (oauthElement) {
    lti_form.removeChild(oauthElement);
  }

  // Get all form elements and convert it into an array.
  // Useful when we want to work with map, filter, reduce, etc...
  const elements = [...lti_form.querySelectorAll("input,select")];

  // Calculate and add oauth_signature element to the form
  const { url: urlElement, secret: secretElement } = post_form.elements;
  const url = urlElement.value;
  const secret = secretElement.value;
  const params = elements.reduce((acc, elem) => ({ ...acc, [elem.name]: elem.value }), {});
  const oauthOptions = { encodeSignature: false };
  const oauth_signature = oauthSignature.generate("POST", url, params, secret, undefined, oauthOptions);
  lti_form.setAttribute("action", url);

  const input = document.createElement("input");
  input.setAttribute("type", "hidden");
  input.setAttribute("name", "oauth_signature");
  input.setAttribute("value", oauth_signature);
  lti_form.appendChild(input);

  // Enable disabled elements to have them sent in the form
  const disabledElements = elements.filter(elem => elem.hasAttribute("disabled"));
  disabledElements.forEach(elem => elem.removeAttribute("disabled"));

  // Disable them again a brief time after the form is submitted
  setTimeout(() => disabledElements.forEach(elem => elem.setAttribute("disabled", "disabled")));

  return true;
});

window.addEventListener("beforeunload", e => (e.returnValue = "Data will be lost if you leave the page, are you sure?"));
