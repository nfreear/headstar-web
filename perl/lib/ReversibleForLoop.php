<?php
/**
 * Enclose code in a "for loop" that can easily be switched between ascending and descending.
 *
 * @copyright © Nick Freear, 26-November-2017.
 * @link https://gist.github.com/nfreear/3bc3550d904a3edc0916386c63db143f#
 */

/* USAGE:

$archive = [];
$count = 0;

$for = new Nfreear\ReversibleForLoop(START_YEAR, END_YEAR + 1, IS_ASCEND);

$for->loop(function ($year) use ($count, &$archive) {

    // Do something ...

});

*/

namespace Nfreear;

class ReversibleForLoop {

    protected $bottom;
    protected $top;
    protected $ascend;
    protected $jump;

    /**
     * @param int  $bottom Bottom of the for-loop.
     * @param int  $top    Top of the loop.
     * @param bool $ascend Ascend or descend?
     * @param int  $jump   Interval for the for-loop.
     */
    public function __construct($bottom = 0, $top = 10, $ascend = true, $jump = 1) {
        $this->bottom = $bottom;
        $this->top = $top;
        $this->ascend = $ascend;
        $this->jump = $jump;
    }

    /** Alias for "execute".
     *
     * @param callable $callable Function, closure function.
     * @return int Count
     */
    public function loop($callable) {
        return $this->execute($callable);
    }

    /** Execute or run the for-loop.
     *
     * @param callable $callable Function, closure function.
     * @return int Count
     */
    public function execute($callable) {
        $count = 0;

        if ($this->ascend) {
            for ($idx = $this->bottom; $idx < $this->top; $idx += $this->jump) {
                $callable( $idx );
                $count++;
            }
        }
        // Descend.
        else {
            $idx = $this->top - $this->jump;
            for ($idx; $idx >= $this->bottom; $idx -= $this->jump) {
                $callable( $idx );
                $count++;
            }
        }
        return $count;
    }
}

// End.
