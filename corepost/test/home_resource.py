'''
Server tests
@author: jacekf
'''

from corepost.web import CorePost, route
from corepost.enums import Http
from twisted.internet import defer
from xml.etree import ElementTree
import json, yaml

class HomeApp(CorePost):
    
    @route("/",Http.GET)
    @defer.inlineCallbacks
    def root(self,request,**kwargs):
        yield 1
        request.write("%s" % kwargs)
        request.finish()
    
    @route("/test",Http.GET)
    def test(self,request,**kwargs):
        return "%s" % kwargs
    
    @route("/test/<int:numericid>/resource/<stringid>",Http.GET)
    def test_get_resources(self,request,numericid,stringid,**kwargs):
        return "%s - %s" % (numericid,stringid)
    
    @route("/post",(Http.POST,Http.PUT))
    def test_post(self,request,**kwargs):
        return "%s" % kwargs
    
    @route("/put",(Http.POST,Http.PUT))
    def test_put(self,request,**kwargs):
        return "%s" % kwargs
    
    @route("/postput",(Http.POST,Http.PUT))
    def test_postput(self,request,**kwargs):
        return "%s" % kwargs
    
    @route("/delete",Http.DELETE)
    def test_delete(self,request,**kwargs):
        return "%s" % kwargs
    
    @route("/post/json",(Http.POST,Http.PUT))
    def test_json(self,request,**kwargs):
        return "%s" % json.dumps(request.json)

    @route("/post/xml",(Http.POST,Http.PUT))
    def test_xml(self,request,**kwargs):
        return "%s" % ElementTree.tostring(request.xml)

    @route("/post/yaml",(Http.POST,Http.PUT))
    def test_yaml(self,request,**kwargs):
        return "%s" % yaml.dump(request.yaml,indent=4,width=130,default_flow_style=False)


def run_app_home():
    app = HomeApp()
    app.run()
    
if __name__ == "__main__":
    run_app_home()