<?php

/**
 * @file
 * Contains \Drupal\app\Controller\AppController.
 */

namespace Drupal\app\Controller;

use Drupal\Core\Controller\ControllerBase;

/**
 * Provides route responses for the app module.
 */
class AppController extends ControllerBase {

  /**
   * Returns a simple page.
   *
   * @return array
   *   A simple renderable array.
   */
  public function dashboard() {
    return array(
      '#theme' => 'app',
    );
  }
}
