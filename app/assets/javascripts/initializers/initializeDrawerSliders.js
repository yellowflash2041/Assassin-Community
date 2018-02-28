function initializeDrawerSliders() {
  if(!initializeSwipeGestures.called) {
    swipeState = "middle";
    initializeSwipeGestures();
  }
  if (document.getElementById("on-page-nav-controls")){
    if (document.getElementById("sidebar-bg-left")){
      document.getElementById("sidebar-bg-left").onclick = function(){
        swipeState = "middle";
        slideSidebar("left","outOfView");
      }
    }
    if (document.getElementById("sidebar-bg-right")){
      document.getElementById("sidebar-bg-right").onclick = function(){
        swipeState = "middle";
        slideSidebar("right","outOfView");
      }
    }

    if (document.getElementById("on-page-nav-butt-left")){
      document.getElementById("on-page-nav-butt-left").onclick = function(){
        swipeState = "left"
        slideSidebar("left","intoView");
      }
    }
    if (document.getElementById("on-page-nav-butt-right")){
      document.getElementById("on-page-nav-butt-right").onclick = function(){
        swipeState = "right"
        slideSidebar("right","intoView");
      }
    }
    InstantClick.on('change', function() {
      document.getElementsByTagName('body')[0].classList.remove('modal-open');
      slideSidebar("right","outOfView");
      slideSidebar("left","outOfView");
    });

  }
}
