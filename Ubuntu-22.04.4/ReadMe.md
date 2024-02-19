I want to give credit to <a href="https://github.com/severach">@severach</a> for these scripts. 
You can view the original post <a href="https://github.com/hehol/t38modem/issues/7">Here</a> which I raised in the t38modem GitHub page.
<br/>
<br/>
To Build, start with the ptlib folder, run `sudo ./mk-ptlib-ubuntu.sh`, allow it to download the required packages and build it.
<br/>
<br/>
Then Build Opal. `cd` into the opal directory and run `sudo ./mk-opal-ubuntu.sh`
<br/>
<br/>
Finally build t39model. `cd` into the t38modem directory and run `sudo ./mk-t38modem-ubuntu.sh`
<br/>
<br/>
Each directory will contain a `src` directory you can run `sudo make install` or look for the `*.ubuntu.pkg.tar.gz` file which will contain 
each built library.
