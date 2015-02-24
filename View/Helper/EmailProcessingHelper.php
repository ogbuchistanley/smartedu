<?php

App::uses('AppHelper', 'Helper');

App::uses('InlineCssLib', 'Lib');

class EmailProcessingHelper extends AppHelper {

/**
* Process Email HTML content after rendering of the email
*
* @param string $layoutFile The layout file that was rendered.
* @return void
*/
    public function afterLayout($layoutFile) {
        $content = $this->_View->Blocks->get('content');
        //$content = $Message->prepareHtmlContent($content, array());

        if (!isset($this->InlineCss)) {
            $this->InlineCss = new InlineCssLib();
        }
        $content = trim($this->InlineCss->process($content));

        $this->_View->Blocks->set('content', $content);
    }

}
