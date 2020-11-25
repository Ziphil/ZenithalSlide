//


let index = 0;

function prepare() {
  let size = document.querySelectorAll("*[class$='slide']").length;
  document.addEventListener("keydown", (event) => {
    if (event.key === "ArrowLeft" || event.key === "ArrowUp" || event.key === "Backspace") {
      if (index > 0) {
        index --;
      }
      scroll();
    } else if (event.key === "ArrowRight" || event.key === "ArrowDown" || event.key === "Enter" || event.key === " ") {
      if (index < size - 1) {
        index ++;
      }
      scroll();
    }
  });
}

function scroll() {
  document.querySelectorAll("*[class$='slide']")[index].scrollIntoView();
  console.log("Page: " + index);
}

window.onload = prepare;