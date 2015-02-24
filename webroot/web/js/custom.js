/*global jQuery:false */
jQuery(document).ready(function($) {
"use strict";

    // Portfolio filter
	$('.portfolio-categ a').click(function(e){
		e.preventDefault();

		var selector = $(this).attr('data-filter');
		$('.portfolio').isotope({ filter: selector });

		$(this).parents('ul').find('li').removeClass('active');
		$(this).parent().addClass('active');
	    });
    
	// Search form
	$('.header-search').click(function(){
		$('.header-search-form').css({ 'display' : 'block' });
		$('.header-search-input').focus();
		$('.header-search-input').keyup(autoResize);
		$('.header-search-input').keydown(checksubmit);
	});
	
	$('.header-search-form').click(function(e){
		var target = e.target;

		while (target.nodeType != 1) target = target.parentNode;
		if(target.tagName != 'TEXTAREA'){
			$('.header-search-form').css({ 'display' : 'none' });
		}
	});

     // Progress bars
     $('.progress-bar').appear(function() {
		$('.progress').each(function() {
			var percentage = $(this).find('.bar').data('percentage');
			$(this).find('.bar').css('width', '0%');
			$(this).find('.bar').animate({
				width: percentage+'%'
			}, '1000');
		});
	   });
	   
	   // FAQ tabs
	   $('.faq-tabs a').click(function(e){
		e.preventDefault();

		var selector = $(this).attr('data-filter');

		$('.portfolio-wrapper .faq-item').fadeOut();
		$('.portfolio-wrapper .faq-item'+selector ).fadeIn();

		$(this).parents('ul').find('li').removeClass('active');
		$(this).parent().addClass('active');
	});
	   
	   	// Tabs
	//When page loads...
	$('.tabs-wrapper').each(function() {
		$(this).find(".tab-pane").hide(); //Hide all content
		$(this).find("ul.nav-tabs li:first").addClass("active").show(); //Activate first tab
		$(this).find(".tab-pane:first").show(); //Show first tab content
	});
	
	//On Click Event
	$("ul.nav-tabs li").click(function(e) {
		$(this).parents('.tabs-wrapper').find("ul.nav-tabs li").removeClass("active"); //Remove any "active" class
		$(this).addClass("active"); //Add "active" class to selected tab
		$(this).parents('.tabs-wrapper').find(".tab-pane").hide(); //Hide all tab content

		var activeTab = $(this).find("a").attr("href"); //Find the href attribute value to identify the active tab + content
		$(this).parents('.tabs-wrapper').find(activeTab).fadeIn(); //Fade in the active ID content
		
		e.preventDefault();
	});
	
	$("ul.nav-tabs li a").click(function(e) {
		e.preventDefault();
	});

	(function() {

		var $menu = $('.navigation nav'),
			optionsList = '<option value="" selected>Go to..</option>';

		$menu.find('li').each(function() {
			var $this   = $(this),
				$anchor = $this.children('a'),
				depth   = $this.parents('ul').length - 1,
				indent  = '';

			if( depth ) {
				while( depth > 0 ) {
					indent += ' - ';
					depth--;
				}

			}
			$(".nav li").parent().addClass("bold");

			optionsList += '<option value="' + $anchor.attr('href') + '">' + indent + ' ' + $anchor.text() + '</option>';
		}).end()
		.after('<select class="selectmenu">' + optionsList + '</select>');
		
		$('select.selectmenu').on('change', function() {
			window.location = $(this).val();
		});
		
	})();

	 
		  $('.toggle-link').each(function() {
			$(this).click(function() {
			  var state = 'open'; //assume target is closed & needs opening
			  var target = $(this).attr('data-target');
			  var targetState = $(this).attr('data-target-state');
			  
			  //allows trigger link to say target is open & should be closed
			  if (typeof targetState !== 'undefined' && targetState !== false) {
				state = targetState;
			  }
			  
			  if (state == 'undefined') {
				state = 'open';
			  }
			  
			  $(target).toggleClass('toggle-link-'+ state);
			  $(this).toggleClass(state);      
			});
		  });
	
		//add some elements with animate effect

		$(".big-cta").hover(
			function () {
			$('.cta a').addClass("animated shake");
			},
			function () {
			$('.cta a').removeClass("animated shake");
			}
		);
		$(".box").hover(
			function () {
			$(this).find('.icon').addClass("animated pulse");
			$(this).find('.text').addClass("animated fadeInUp");
			$(this).find('.image').addClass("animated fadeInDown");
			},
			function () {
			$(this).find('.icon').removeClass("animated pulse");
			$(this).find('.text').removeClass("animated fadeInUp");
			$(this).find('.image').removeClass("animated fadeInDown");
			}
		);
		
		// Accordion
		$('.accordion').on('show', function (e) {
		
			$(e.target).prev('.accordion-heading').find('.accordion-toggle').addClass('active');
			$(e.target).prev('.accordion-heading').find('.accordion-toggle i').removeClass('icon-plus');
			$(e.target).prev('.accordion-heading').find('.accordion-toggle i').addClass('icon-minus');
		});
		
		$('.accordion').on('hide', function (e) {
			$(this).find('.accordion-toggle').not($(e.target)).removeClass('active');
			$(this).find('.accordion-toggle i').not($(e.target)).removeClass('icon-minus');
			$(this).find('.accordion-toggle i').not($(e.target)).addClass('icon-plus');
		});	

        $('.opener').click(function() {
         $(this).toggleClass('font-icon-plus-sign');
         $(this).toggleClass('font-icon-remove-sign');
        });


		// tooltip
		$('.social-network li a, .options_box .color a, .tool-tip').tooltip();

		// fancybox
		$(".fancybox").fancybox({				
				padding : 0,
				autoResize: true,
				beforeShow: function () {
					this.title = $(this.element).attr('title');
					this.title = '<h4>' + this.title + '</h4>' + '<p>' + $(this.element).parent().find('img').attr('alt') + '</p>';
				},
				helpers : {
					title : { type: 'inside' },
					media: true,
				}
			});

		
		//scroll to top
		$(window).scroll(function(){
			if ($(this).scrollTop() > 100) {
				$('.scrollup').fadeIn();
				} else {
				$('.scrollup').fadeOut();
			}
		});
		$('.scrollup').click(function(){
			$("html, body").animate({ scrollTop: 0 }, 1000);
				return false;
		});

	   //nivo slider
		$('.nivo-slider').css({'visibility':'visible'}).nivoSlider({
			effect: 'random', // Specify sets like: 'fold,fade,sliceDown'
			slices: 15, // For slice animations
			boxCols: 8, // For box animations
			boxRows: 4, // For box animations
			animSpeed: 500, // Slide transition speed
			pauseTime: 5000, // How long each slide will show
			startSlide: 0, // Set starting Slide (0 index)
			directionNav: true, // Next & Prev navigation
			controlNav: true, // 1,2,3... navigation
			controlNavThumbs: false, // Use thumbnails for Control Nav
			pauseOnHover: true, // Stop animation while hovering
			manualAdvance: false, // Force manual transitions
			prevText: '', // Prev directionNav text
			nextText: '', // Next directionNav text
			randomStart: false, // Start on a random slide
			beforeChange: function(){}, // Triggers before a slide transition
			afterChange: function(){}, // Triggers after a slide transition
			slideshowEnd: function(){}, // Triggers after all slides have been shown
			lastSlide: function(){}, // Triggers when last slide is shown
			afterLoad: function(){} // Triggers when slider has loaded
		});
		
		//flexslider
		$('.flexslider').flexslider(
		{animation: "slide",
		}
		);
		

        //flexisel
	    $("#flexisel").flexisel({
		visibleItems: 3,
		animationSpeed: 500,
		autoPlay: false,
		autoPlaySpeed: 3000,    		
		pauseOnHover: true,
		enableResponsiveBreakpoints: true,
    	responsiveBreakpoints: { 
    		portrait: { 
    			changePoint:480,
    			visibleItems: 1
    		}, 
    		landscape: { 
    			changePoint:640,
    			visibleItems: 2
    		},
    		tablet: { 
    			changePoint:768,
    			visibleItems: 2
    		}
    	}
        }); 
		
		$("#flexisel2").flexisel({
		visibleItems: 6,
		animationSpeed: 500,
		autoPlay: false,
		autoPlaySpeed: 3000,    		
		pauseOnHover: true,
		enableResponsiveBreakpoints: true,
    	responsiveBreakpoints: { 
    		portrait: { 
    			changePoint:480,
    			visibleItems: 3
    		}, 
    		landscape: { 
    			changePoint:640,
    			visibleItems: 4
    		},
    		tablet: { 
    			changePoint:768,
    			visibleItems: 5
    		}
    	}
        });
    


        
});

// Sticky menu
$(document).ready(function() {
	$('.fixed-menu').waypoint('sticky', {
  wrapper: '<div class="sticky-wrapper" />',
  stuckClass: 'stuck'
});
});