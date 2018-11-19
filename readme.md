# DO API dot sh!
## dopey :D

This script is just a wrapper for the digital ocean api to make life a little easier if you need to add and remove hosts quickly, always tend to use the same regions and slug sizes, or have a domain in DO that you want to add/remove records from and you just want to do it super fast without having to go through the gui. 

Some of the things I wanted to make easy:
- create a droplet and also add a dns name for it at the same time, on the same command line
- create an image from a specified snapshot in one command line
- interact with a domain hosted with DO, add records, delete records, with short command lines

Every attacker has had to deal with burned infrastructure in the past and I'm sure will appreciate the ability to quickly nuke burned c2 infra and stand up new infra super fast. 

## Basic Usage
./do_api.sh [names or data] [operation]

This is because I'm not handy enough in bash to figure out how to take user args "that will go anywhere", and I had to structure the script to operate such that the 'options' went first, and the 'operation' went last.

## Example
- ./do_api.sh --list-droplets
- ./do_api.sh --domain hax.lol --subdomain wut --add-subdomain
- ./do_api.sh --name lolwut --add-droplet
- ./do_api.sh --name ultrawut --region ams3 --size s-2vcpu-4gb --add-droplet
- ./do_api.sh --list-snapshots
- ./do_api.sh --name sweetsweetrestore --snapshot 1123123123 --add-droplet
(I'm sat in an airport right now, so I'm doing skeletonized documentation for now, until I can add some meat. Please have a look at the script to see additional details for now, I tried to make it pretty easy to read)


There are some defaults. If size and region arent specified on create, it'll default to what is specified at the top of the script (you may change it if you wish) and the 's-1vcpu-2gb' size.

This script is also still a work and progress and it needs some polish. 

## TODO

- make a pretty usage
- figure out how to make the cmdline args go 'in any order'
- pretty up the output
- add a verbose flag that spits out more output
