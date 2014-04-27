# PraxPress

An OS X Desktop application for managing online services. __SoundCloud__ and __WordPress__ are currently supported, but the project may be expanded to include others.

With hundreds of tracks hosted on SoundCloud, I wanted an easier way to manage all their details and settings. I also wanted an easier way to create pages embedded with multiple SoundCloud players on my WordPress site, including an easier and consistent way to manage the settings of all those players!

## Description

#### Creates Local Database from Cloud Metadata

PraxPress connects directly to the cloud-hosted service's API and downloads all of the metadata for all of the user's assets on the service.

* For __WordPress__, this is all of the information and settings about all of the posts and pages on the user's WordPress.com hosted blog. 

* For __SoundCloud__, it's everything about the user's tracks and playlists. PraxPress doesn't download the actual sound files, but it downloads everything about the track or playlist; title, genre, description, tags, etc.; and also the URLs for linking to the sounds on SoundCloud, and for embedding SoundCloud players.

Beause it's just collecting the metadata, the downloads are very fast! PraxPress stores all this information in a ".praxpress" database file, saved locally on the user's computer.

PraxPress allows you to manipulate and modify this local database in many ways, without changing anything on the servers. Then; only when you're happy with any changes made locally; PraxPress can upload the data to the cloud and the changes will go online.

#### Organize Cloud Assets

But that's just part of what PraxPress does. Because all the information is in a local database, you can quickly search, sort, and filter through hundreds of assets; via any of the items' metadata or many other detail fields.

Being able to see exactly what you've got hosted in the cloud is the first step in getting it organized better. PraxPress gives you a "wide angled lens" to see everything at once, with the ability to focus on particular items, and to group various items together in different ways.

#### Make Multiple Changes

PraxPress makes it easy to change any of the individual metadata fields for any item, or to make changes for many items at the same time. PraxPress can manipulate the titles and descriptions of multiple items; searching for and replacing specific text, and/or adding/deleting text in various ways. Item tags can be added, removed, and/or merged among multiple items.

#### Generate HTML Code

After you've praxed up all your online assets, PraxPress will help you publish them by generating HTML, or any other kind of code you wish. Through a flexible system of templates, PraxPress can insert any desired metadata into a template code segment; repeating the code for any number of items.

For example; a page with dozens of specific SoundCloud players; or, a page with hundreds of SoundCloud track titles linked to their corresponding pages on SoundCloud. If a SoundCloud track or playlist has an artwork image, PraxPress will know all about it and make it easy to embed various sizes in your code.

To help you design your code templates, PraxPress can continuously save the generated output code in a local HTML file and immediately display the page for you to view in Safari. It's easy to experiment with different elements and styles, creating interesting effects for your items, from simple to very complex presentations.

### Prax + Press = PraxPress!

When you've finally made your code so prax that you're ready to "press", copy and paste it into a WordPress page or anywhere you wish!


## Getting started

### Get the sources

`git clone git://github.com/ElmerCat/PraxPress.git`

### Praxxx
<img src="http://elmercatdotorg.files.wordpress.com/2014/03/scollay-s.jpg"/>

Prax

#### Praxxxx

Prax

## Praxx

Prax

## BSD License 

Copyright © 2014, ElmerCat / ElmerCat.org

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.
* Neither the name of ElmerCat nor the
  names of its contributors may be used to endorse or promote products
  derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
