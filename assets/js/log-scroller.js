export function scroll_log(target) {
  if (target) {
    window.logObserver = new MutationObserver(function(
      mutationsList,
      observer
    ) {
      // const lastMutation = mutationsList[mutationsList.length - 1];
      // const lastNode =
      //   lastMutation.addedNodes[lastMutation.addedNodes.length - 1];
      // lastNode.scrollIntoView({ behavior: "smooth", block: "end" });

      target.scrollTop = target.scrollHeight;
    });

    window.logObserver.observe(target, {
      attributes: false,
      childList: true,
      subtree: true
    });

    console.log("Observing");

    target.scrollTop = target.scrollHeight;
  }
}
