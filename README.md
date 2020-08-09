# NAME

**srcset.sh** -- generate multiple responsive images for web and mobile.

## SYNOPSIS
`srset.sh [-hmzug] [-q quality] [—t type] [-s sizes] [-o outdirectory] [-f filename] filename`
`srset.sh [-hmzug] [—n findname] [-q quality] [—t type] [-s sizes] [-o outpath] [-f filepath] filepath`
  
## Diff to the original script from adrianboston
For general usage please take a look at the original srcset.sh documentation on github 
[adrianboston/srcset.sh](https://github.com/adrianboston/srcset.sh)
  
This fork is meant as watchdog for new files in a web directory (e.g. periodically 
called by a cronjob), which should run in the background.
  
## Additional attributes:
- `-g`: gitignore - write the created images into a .gitignore file
- `-u`: subdirectory - place the created images in a subdirectory. The name 
of the subdirectory is identical to the name of the source image file.

The set of image widths / quality settings can be configured in the file 
srcset.conf, which must be in the same directory as this srcset.sh.  
If the file does not exist, it will be created with some default values.  
  
The filename of every already processed image will be attached to the file 
`processed_images` within the same directory as this srcset.sh.  
The files from the list in `processed_images` will be skipped in future 
calls of this script.

## Example:

To call the script every 60 seconds via cron, add a line to the cron configuration (in this example for the user `www-data`.

- Open crontab for user `www-data`:

```bash
sudo -u www-data crontab -e
```

- Add this line at the end of the cron configuration:
```bash
*  *  *  *  * /var/www/html/grav/user/srcset.sh -f /var/www/html/grav/user/pages/ -g -u -n *-responsive.jpg
```

This will call the `srcset.sh` every 60 seconds to check for new files with the suffix `-responsive.jpg` within the folder `/var/www/html/grav/user/pages/`

If a file with the suffix `-responsive.jpg` is found, responsive versions of this file will be created within a subfolder `<original-image-name-without-ext>`.  
For example: If a new file `foo-bar-responsive.jpg` is detected in the folder `var/www/html/grav/user/pages/01.home/01.main/`, a set of responsive version (based on the configuration in `srcset.conf` is created in `var/www/html/grav/user/pages/01.home/01.main/foo-bar-responsive/`:  
- foo-bar-responsive-240w.jpg
- foo-bar-responsive-320w.jpg
- foo-bar-responsive-480w.jpg
- foo-bar-responsive-640w.jpg
- foo-bar-responsive-720w.jpg
- foo-bar-responsive-960w.jpg
- foo-bar-responsive-1100w.jpg  
...
