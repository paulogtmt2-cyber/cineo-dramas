package br.com.cineo;
import java.io.File;
class MainActivity {String uid="account-a",viewerId="",viewerToken="",viewerName="";boolean viewerKids=false;int viewerMaxRating=18;final File files;MainActivity(File path){files=path;}File getFilesDir(){return files;}}
