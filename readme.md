# DO API dot sh!
## dopey :D

This script is just a wrapper for the digital ocean api to make life a little easier if you need to add and remove hosts quickly, always tend to use the same regions and slug sizes, or have a domain in DO that you want to add/remove records from and you just want to do it super fast without having to go through the gui. 

## Basic Usage
./do_api.sh [names or data] [operation]

This is because I'm not handy enough in bash to figure out how to take user args "that will go anywhere", and I had to structure the script to operate such that the 'options' went first, and the 'operation' went last. 

## Example
- ./do_api.sh --list-droplets
- ./do_api.sh --domain hax.lol --subdomain wut --add-subdomain
- ./do_api.sh --name lolwut --add-droplet
- ./do_api.sh --name ultrawut --region ams3 --size s-2vcpu-4gb --add-droplet


There are some defaults. If size and region arent specified on create, it'll default to what is specified at the top of the script (you may change it if you wish) and the 's-1vcpu-2gb' size.

This script is also still a work and progress and it needs some polish. 

## TODO

- make a pretty usage
- figure out how to make the cmdline args go 'in any order'
- pretty up the output
- add a verbose flag that spits out more output
