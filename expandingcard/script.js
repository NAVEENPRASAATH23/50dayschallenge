var activeElement = null;

function toggleHover(element) {
    if (activeElement) {
        // If there is an active element, reset its width and remove the "active" class
        activeElement.style.width = "100px";
        activeElement.classList.remove('active');
    }

    // Set the width of the clicked element to 300px and add the "active" class
    element.style.width = "300px";
    element.classList.add('active');

    // Set the clicked element as the active element
    activeElement = element;
}
