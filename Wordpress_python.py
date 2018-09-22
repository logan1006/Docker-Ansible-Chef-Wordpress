#!/usr/bin/python
from wordpress_xmlrpc import Client, WordPressPost
from wordpress_xmlrpc.methods.posts import GetPosts, NewPost
from wordpress_xmlrpc.methods.users import GetUserInfo
import re
import os
f = open('sample.txt') 
data = f.readline()

wp = Client('https://wordpress.com/posts/https24711954.wordpress.com', 'https24711954', 'Chetan_sharma10')
wp.call(GetPosts())
wp.call(GetUserInfo())
post = WordPressPost()
post.title = 'Life'
post.content = data
post.terms_names = {'post_tag': ['1', 'mypost'],'category': ['humans', 'awesome']}
wp.call(NewPost(post))