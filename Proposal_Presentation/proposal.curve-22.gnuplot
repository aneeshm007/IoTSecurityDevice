set table "proposal.curve-22.table"; set format "%.5f"
 f(x,y) = y**2 - x**3 - -2*x - 2; set xrange [-3:3]; set yrange [-3:3]; set view 0,0; set isosample 50,50; set cont base; set cntrparam levels incre 0,0.1,0; unset surface; splot f(x,y); 
