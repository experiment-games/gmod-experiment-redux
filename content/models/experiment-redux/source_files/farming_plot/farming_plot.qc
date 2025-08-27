$modelname "experiment-redux/farming_plot"
$staticprop
$casttextureshadows
$origin 0 0 0 -90
$model mesh "farming_plot.smd"
$surfaceprop "wood"
$cdmaterials "models/experiment-redux/farming_plot/de_cbble"
$cdmaterials "models/experiment-redux/farming_plot/de_chateau"
$collisionmodel "farming_plot_phys.smd"
{
	$automass
	$concave
	$remove2d
	$maxconvexpieces 1000000
}
$sequence ref "farming_plot.smd"
