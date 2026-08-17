
((window,document,undefined)=>{'use strict';const env={};const toCamelCase=s=>s.replace(/(?:^|[. -])(.)/g,(m0,m1)=>m1.toUpperCase());const superContext={};let classIndex=0;const Class=Object.assign(function(){},{extend(properties){const props={__id__:{value:classIndex},__base__:{value:this.prototype},__name__:{value:properties.__name__??`anonymous${classIndex++}`}};const ClassConstructor=function(){if(!(this instanceof ClassConstructor))
throw new TypeError('Constructor must not be called without "new"');if(Object.getPrototypeOf(this).hasOwnProperty('__init__')){if(typeof(this.__init__)!='function')
throw new TypeError('Class __init__ member is not a function');this.__init__.apply(this,arguments)}
else{this.super('__init__',arguments);}};for(const key in properties)
if(!props[key]&&properties.hasOwnProperty(key))
props[key]={value:properties[key],writable:true};ClassConstructor.prototype=Object.create(this.prototype,props);ClassConstructor.prototype.constructor=ClassConstructor;Object.assign(ClassConstructor,this);ClassConstructor.displayName=toCamelCase(`${props.__name__.value}Class`);return ClassConstructor;},singleton(properties,...new_args){return Class.extend(properties).instantiate(new_args);},instantiate(args){return new(Function.prototype.bind.call(this,null,...args))();},call(self,method,...args){if(typeof(this.prototype[method])!='function')
throw new ReferenceError(`${method} is not defined in class`);return this.prototype[method].call(self,method,...args);},isSubclass(classValue){return(typeof(classValue)=='function'&&classValue.prototype instanceof this);},prototype:{varargs(args,offset,...extra_args){return extra_args.concat(Array.prototype.slice.call(args,offset));},super(key,...callArgs){if(key==null)
return null;const slotIdx=`${this.__id__}.${key}`;const symStack=superContext[slotIdx];let protoCtx=null;for(protoCtx=Object.getPrototypeOf(symStack?symStack[0]:Object.getPrototypeOf(this));protoCtx!=null&&!protoCtx.hasOwnProperty(key);protoCtx=Object.getPrototypeOf(protoCtx)){}
if(protoCtx==null)
return null;let res=protoCtx[key];if(callArgs.length>0){if(typeof(res)!='function')
throw new ReferenceError(`${key} is not a function in base class`);if(Array.isArray(callArgs[0])||LuCI.prototype.isArguments(callArgs[0]))
callArgs=callArgs[0];if(symStack)
symStack.unshift(protoCtx);else
superContext[slotIdx]=[protoCtx];res=res.apply(this,callArgs);if(symStack&&symStack.length>1)
symStack.shift(protoCtx);else
delete superContext[slotIdx];}
return res;},toString(){let s=`[${this.constructor.displayName}]`,f=true;for(const k in this){if(this.hasOwnProperty(k)){s+=`${f ? ' {\n' : ''}  ${k}: ${typeof(this[k])}\n`;f=false;}}
return s+(f?'':'}');}}});const Headers=Class.extend({__name__:'LuCI.headers',__init__(xhr){const hdrs=this.headers={};xhr.getAllResponseHeaders().split(/\r\n/).forEach(line=>{const m=/^([^:]+):(.*)$/.exec(line);if(m!=null)
hdrs[m[1].trim().toLowerCase()]=m[2].trim();});},has(name){return this.headers.hasOwnProperty(String(name).toLowerCase());},get(name){const key=String(name).toLowerCase();return this.headers.hasOwnProperty(key)?this.headers[key]:null;}});const Response=Class.extend({__name__:'LuCI.response',__init__(xhr,url,duration,headers,content){this.ok=(xhr.status>=200&&xhr.status<=299);this.status=xhr.status;this.statusText=xhr.statusText;this.headers=(headers!=null)?headers:new Headers(xhr);this.duration=duration;this.url=url;this.xhr=xhr;if(content instanceof Blob){this.responseBlob=content;this.responseJSON=null;this.responseText=null;}
else if(content!=null&&typeof(content)=='object'){this.responseBlob=null;this.responseJSON=content;this.responseText=null;}
else if(content!=null){this.responseBlob=null;this.responseJSON=null;this.responseText=String(content);}
else{this.responseJSON=null;if(xhr.responseType=='blob'){this.responseBlob=xhr.response;this.responseText=null;}
else{this.responseBlob=null;this.responseText=xhr.responseText;}}},clone(content){const copy=new Response(this.xhr,this.url,this.duration,this.headers,content);copy.ok=this.ok;copy.status=this.status;copy.statusText=this.statusText;return copy;},json(){if(this.responseJSON==null)
this.responseJSON=JSON.parse(this.responseText);return this.responseJSON;},text(){if(this.responseText==null&&this.responseJSON!=null)
this.responseText=JSON.stringify(this.responseJSON);return this.responseText;},blob(){return this.responseBlob;}});const requestQueue=[];function isQueueableRequest(opt){if(!classes.rpc)
return false;if(opt.method!='POST'||typeof(opt.content)!='object')
return false;if(opt.nobatch===true)
return false;const rpcBaseURL=Request.expandURL(classes.rpc.getBaseURL());return(rpcBaseURL!=null&&opt.url.indexOf(rpcBaseURL)==0);}
function flushRequestQueue(){if(!requestQueue.length)
return;const reqopt=Object.assign({},requestQueue[0][0],{content:[],nobatch:true}),batch=[];for(let i=0;i<requestQueue.length;i++){batch[i]=requestQueue[i];reqopt.content[i]=batch[i][0].content;}
requestQueue.length=0;Request.request(rpcBaseURL,reqopt).then(reply=>{let json=null,req=null;try{json=reply.json()}
catch(e){}
while((req=batch.shift())!=null)
if(Array.isArray(json)&&json.length)
req[2].call(reqopt,reply.clone(json.shift()));else
req[1].call(reqopt,new Error('No related RPC reply'));}).catch(error=>{let req=null;while((req=batch.shift())!=null)
req[1].call(reqopt,error);});}
const Request=Class.singleton({__name__:'LuCI.request',interceptors:[],expandURL(url){if(!/^(?:[^/]+:)?\/\//.test(url))
url=`${location.protocol}//${location.host}${url}`;return url;},request(target,options){return Promise.resolve(target).then(url=>{const state={xhr:new XMLHttpRequest(),url:this.expandURL(url),start:Date.now()};const opt=Object.assign({},options,state);let content=null;let contenttype=null;const callback=this.handleReadyStateChange;return new Promise((resolveFn,rejectFn)=>{opt.xhr.onreadystatechange=callback.bind(opt,resolveFn,rejectFn);opt.method=String(opt.method??'GET').toUpperCase();if('query'in opt){const q=(opt.query!=null)?Object.keys(opt.query).map(k=>{if(opt.query[k]!=null){const v=(typeof(opt.query[k])=='object')?JSON.stringify(opt.query[k]):String(opt.query[k]);return'%s=%s'.format(encodeURIComponent(k),encodeURIComponent(v));}
else{return encodeURIComponent(k);}}).join('&'):'';if(q!==''){switch(opt.method){case'GET':case'HEAD':case'POST':case'OPTIONS':opt.url+=((/\?/).test(opt.url)?'&':'?')+q;break;default:if(content==null){content=q;contenttype='application/x-www-form-urlencoded';}}}}
if(!opt.cache)
opt.url+=((/\?/).test(opt.url)?'&':'?')+(new Date()).getTime();if(isQueueableRequest(opt)){requestQueue.push([opt,rejectFn,resolveFn]);requestAnimationFrame(flushRequestQueue);return;}
if('username'in opt&&'password'in opt)
opt.xhr.open(opt.method,opt.url,true,opt.username,opt.password);else
opt.xhr.open(opt.method,opt.url,true);opt.xhr.responseType=opt.responseType??'text';if('overrideMimeType'in opt.xhr)
opt.xhr.overrideMimeType('application/octet-stream');if('timeout'in opt)
opt.xhr.timeout=+opt.timeout;if('credentials'in opt)
opt.xhr.withCredentials=!!opt.credentials;if(opt.content!=null){switch(typeof(opt.content)){case'function':content=opt.content(opt.xhr);break;case'object':if(!(opt.content instanceof FormData)){content=JSON.stringify(opt.content);contenttype='application/json';}
else{content=opt.content;}
break;default:content=String(opt.content);}}
if('headers'in opt)
for(const header in opt.headers)
if(opt.headers.hasOwnProperty(header)){if(header.toLowerCase()!='content-type')
opt.xhr.setRequestHeader(header,opt.headers[header]);else
contenttype=opt.headers[header];}
if('progress'in opt&&'upload'in opt.xhr)
opt.xhr.upload.addEventListener('progress',opt.progress);if(opt.responseProgress!=null)
opt.xhr.addEventListener('progress',opt.responseProgress);if(contenttype!=null)
opt.xhr.setRequestHeader('Content-Type',contenttype);try{opt.xhr.send(content);}
catch(e){rejectFn.call(opt,e);}});});},handleReadyStateChange(resolveFn,rejectFn,ev){const xhr=this.xhr,duration=Date.now()-this.start;if(xhr.readyState!==4)
return;if(xhr.status===0&&xhr.statusText===''){if(duration>=this.timeout)
rejectFn.call(this,new Error('XHR request timed out'));else
rejectFn.call(this,new Error('XHR request aborted by browser'));}
else{const response=new Response(xhr,xhr.responseURL??this.url,duration);Promise.all(Request.interceptors.map(fn=>fn(response))).then(resolveFn.bind(this,response)).catch(rejectFn.bind(this));}},get(url,options){return this.request(url,Object.assign({method:'GET'},options));},post(url,data,options){return this.request(url,Object.assign({method:'POST',content:data},options));},addInterceptor(interceptorFn){if(typeof(interceptorFn)=='function')
this.interceptors.push(interceptorFn);return interceptorFn;},removeInterceptor(interceptorFn){const oldlen=this.interceptors.length;let i=oldlen;while(i--)
if(this.interceptors[i]===interceptorFn)
this.interceptors.splice(i,1);return(this.interceptors.length<oldlen);},poll:{add(interval,url,options,callback){if(isNaN(interval)||interval<=0)
throw new TypeError('Invalid poll interval');const ival=interval>>>0,opts=Object.assign({},options,{timeout:ival*1000-5});const fn=()=>Request.request(url,opts).then(res=>{if(!Poll.active())
return;let res_json=null;try{res_json=res.json();}
catch(err){}
callback(res,res_json,res.duration);});return(Poll.add(fn,ival)?fn:null);},remove(entry){return Poll.remove(entry)},start(){return Poll.start()},stop(){return Poll.stop()},active(){return Poll.active()}}});const Poll=Class.singleton({__name__:'LuCI.poll',queue:[],add(fn,interval){if(interval==null||interval<=0)
interval=env.pollinterval||null;if(isNaN(interval)||typeof(fn)!='function')
throw new TypeError('Invalid argument to LuCI.poll.add()');for(let i=0;i<this.queue.length;i++)
if(this.queue[i].fn===fn)
return false;const e={r:true,i:interval>>>0,fn};this.queue.push(e);if(this.tick!=null&&!this.active())
this.start();return true;},remove(fn){if(typeof(fn)!='function')
throw new TypeError('Invalid argument to LuCI.poll.remove()');const len=this.queue.length;for(let i=len;i>0;i--)
if(this.queue[i-1].fn===fn)
this.queue.splice(i-1,1);if(!this.queue.length&&this.stop())
this.tick=0;return(this.queue.length!=len);},start(){if(this.active())
return false;this.tick=0;if(this.queue.length){this.timer=window.setInterval(this.step,1000);this.step();document.dispatchEvent(new CustomEvent('poll-start'));}
return true;},stop(){if(!this.active())
return false;document.dispatchEvent(new CustomEvent('poll-stop'));window.clearInterval(this.timer);delete this.timer;delete this.tick;return true;},step(){for(let i=0,e=null;(e=Poll.queue[i])!=null;i++){if((Poll.tick%e.i)!=0)
continue;if(!e.r)
continue;e.r=false;Promise.resolve(e.fn()).finally((function(){this.r=true}).bind(e));}
Poll.tick=(Poll.tick+1)%Math.pow(2,32);},active(){return(this.timer!=null);}});const DOM=Class.singleton({__name__:'LuCI.dom',elem(e){return(e!=null&&typeof(e)=='object'&&'nodeType'in e);},parse(s){try{return domParser.parseFromString(s,'text/html').body.firstChild;}
catch(e){return null;}},matches(node,selector){const m=this.elem(node)?(node.matches??node.msMatchesSelector):null;return m?m.call(node,selector):false;},parent(node,selector){if(this.elem(node)&&node.closest)
return node.closest(selector);while(this.elem(node))
if(this.matches(node,selector))
return node;else
node=node.parentNode;return null;},append(node,children){if(!this.elem(node))
return null;if(Array.isArray(children)){for(let i=0;i<children.length;i++)
if(this.elem(children[i]))
node.appendChild(children[i]);else if(children!==null&&children!==undefined)
node.appendChild(document.createTextNode(`${children[i]}`));return node.lastChild;}
else if(typeof(children)==='function'){return this.append(node,children(node));}
else if(this.elem(children)){return node.appendChild(children);}
else if(children!==null&&children!==undefined){node.innerHTML=`${children}`;return node.lastChild;}
return null;},content(node,children){if(!this.elem(node))
return null;const dataNodes=node.querySelectorAll('[data-idref]');for(let i=0;i<dataNodes.length;i++)
delete this.registry[dataNodes[i].getAttribute('data-idref')];while(node.firstChild)
node.removeChild(node.firstChild);return this.append(node,children);},attr(node,key,val){if(!this.elem(node))
return null;let attr=null;if(typeof(key)==='object'&&key!==null)
attr=key;else if(typeof(key)==='string')
attr={},attr[key]=val;for(key in attr){if(!attr.hasOwnProperty(key)||attr[key]==null)
continue;switch(typeof(attr[key])){case'function':node.addEventListener(key,attr[key]);break;case'object':node.setAttribute(key,JSON.stringify(attr[key]));break;default:node.setAttribute(key,attr[key]);}}},create(){const html=arguments[0];let attr=arguments[1];let data=arguments[2];let elem;if(!(attr instanceof Object)||Array.isArray(attr))
data=attr,attr=null;if(Array.isArray(html)){elem=document.createDocumentFragment();for(let i=0;i<html.length;i++)
elem.appendChild(this.create(html[i]));}
else if(this.elem(html)){elem=html;}
else if(html.charCodeAt(0)===60){elem=this.parse(html);}
else{elem=document.createElement(html);}
if(!elem)
return null;this.attr(elem,attr);this.append(elem,data);return elem;},registry:{},data(node,key,val){if(!node?.getAttribute)
return null;let id=node.getAttribute('data-idref');if(arguments.length>1&&key==null){if(id!=null){node.removeAttribute('data-idref');val=this.registry[id]
delete this.registry[id];return val;}
return null;}
else if(arguments.length>2&&key!=null&&val==null){if(id!=null){val=this.registry[id][key];delete this.registry[id][key];return val;}
return null;}
else if(arguments.length>2&&key!=null&&val!=null){if(id==null){do{id=Math.floor(Math.random()*0xffffffff).toString(16)}
while(this.registry.hasOwnProperty(id));node.setAttribute('data-idref',id);this.registry[id]={};}
return(this.registry[id][key]=val);}
else if(arguments.length==1){if(id!=null)
return this.registry[id];return null;}
else if(arguments.length==2){if(id!=null)
return this.registry[id][key];}
return null;},bindClassInstance(node,inst){if(!(inst instanceof Class))
LuCI.prototype.error('TypeError','Argument must be a class instance');return this.data(node,'_class',inst);},findClassInstance(node){let inst=null;do{inst=this.data(node,'_class');node=node.parentNode;}
while(!(inst instanceof Class)&&node!=null);return inst;},callClassMethod(node,method,...args){const inst=this.findClassInstance(node);if(typeof(inst?.[method])!='function')
return null;return inst[method].call(inst,...args);},isEmpty(node,ignoreFn){for(let child=node?.firstElementChild;child!=null;child=child.nextElementSibling)
if(!child.classList.contains('hidden')&&!ignoreFn?.(child))
return false;return true;}});const Session=Class.singleton({__name__:'LuCI.session',getID(){return env.sessionid??'00000000000000000000000000000000';},getToken(){return env.token??null;},getLocalData(key){try{const sid=this.getID();const item='luci-session-store';let data=JSON.parse(window.sessionStorage.getItem(item));if(!LuCI.prototype.isObject(data)||!data.hasOwnProperty(sid)){data={};data[sid]={};}
if(key!=null)
return data[sid].hasOwnProperty(key)?data[sid][key]:null;return data[sid];}
catch(e){return(key!=null)?null:{};}},setLocalData(key,value){if(key==null)
return false;try{const sid=this.getID();const item='luci-session-store';let data=JSON.parse(window.sessionStorage.getItem(item));if(!LuCI.prototype.isObject(data)||!data.hasOwnProperty(sid)){data={};data[sid]={};}
if(value!=null)
data[sid][key]=value;else
delete data[sid][key];window.sessionStorage.setItem(item,JSON.stringify(data));return true;}
catch(e){return false;}}});const View=Class.extend({__name__:'LuCI.view',__init__(){const vp=document.getElementById('view');DOM.content(vp,E('div',{'class':'spinning'},_('Loading view…')));const ready=L.loaded?Promise.resolve():new Promise((resolve)=>{document.addEventListener('luci-loaded',resolve,{once:true});});return ready.then(LuCI.prototype.bind(this.load,this)).then(LuCI.prototype.bind(this.render,this)).then(LuCI.prototype.bind(function(nodes){const vp=document.getElementById('view');DOM.content(vp,nodes);DOM.append(vp,this.addFooter());},this)).catch(LuCI.prototype.error);},load(){},render(){},handleSave(ev){const tasks=[];document.getElementById('maincontent').querySelectorAll('.cbi-map').forEach(map=>{tasks.push(DOM.callClassMethod(map,'save'));});return Promise.all(tasks);},handleSaveApply(ev,mode){return this.handleSave(ev).then(()=>{classes.ui.changes.apply(mode=='0');});},handleReset(ev){const tasks=[];document.getElementById('maincontent').querySelectorAll('.cbi-map').forEach(map=>{tasks.push(DOM.callClassMethod(map,'reset'));});return Promise.all(tasks);},addFooter(){const footer=E([]);const vp=document.getElementById('view');let hasmap=false;let readonly=true;vp.querySelectorAll('.cbi-map').forEach(map=>{const m=DOM.findClassInstance(map);if(m){hasmap=true;if(!m.readonly)
readonly=false;}});if(!hasmap)
readonly=!LuCI.prototype.hasViewPermission();const saveApplyBtn=this.handleSaveApply?new classes.ui.ComboButton('0',{0:[_('Save & Apply')],1:[_('Apply unchecked')]},{classes:{0:'btn cbi-button cbi-button-apply important',1:'btn cbi-button cbi-button-negative important'},click:classes.ui.createHandlerFn(this,'handleSaveApply'),disabled:readonly||null}).render():E([]);if(this.handleSaveApply||this.handleSave||this.handleReset){footer.appendChild(E('div',{'class':'cbi-page-actions'},[saveApplyBtn,' ',this.handleSave?E('button',{'class':'cbi-button cbi-button-save','click':classes.ui.createHandlerFn(this,'handleSave'),'disabled':readonly||null},[_('Save')]):'',' ',this.handleReset?E('button',{'class':'cbi-button cbi-button-reset','click':classes.ui.createHandlerFn(this,'handleReset'),'disabled':readonly||null},[_('Reset')]):'']));}
return footer;}});const domParser=new DOMParser();let originalCBIInit=null;let rpcBaseURL=null;let sysFeatures=null;let preloadClasses=null;const classes={baseclass:Class,dom:DOM,poll:Poll,request:Request,session:Session,view:View};const naturalCompare=new Intl.Collator(undefined,{numeric:true}).compare;const LuCI=Class.extend({__name__:'LuCI',__init__(setenv){document.querySelectorAll('script[src*="/luci.js"]').forEach(s=>{if(setenv.base_url==null||setenv.base_url==''){const m=(s.getAttribute('src')??'').match(/^(.*)\/luci\.js(?:\?v=([^?]+))?$/);if(m){setenv.base_url=m[1];setenv.resource_version=m[2];}}});if(setenv.base_url==null)
this.error('InternalError','Cannot find url of luci.js');setenv.cgi_base=setenv.scriptname.replace(/\/[^/]+$/,'');Object.assign(env,setenv);const domReady=new Promise((resolveFn,rejectFn)=>{document.addEventListener('DOMContentLoaded',resolveFn);});Promise.all([domReady,this.require('ui'),this.require('rpc'),this.require('form'),this.probeRPCBaseURL()]).then(this.setupDOM.bind(this)).catch(this.error);originalCBIInit=window.cbi_init;window.cbi_init=()=>{};},raise(type,fmt,...args){let e=null;const msg=fmt?String.prototype.format.call(fmt,...args):null;const stack=[];if(type instanceof Error){e=type;if(msg)
e.message=`${msg}: ${e.message}`;}
else{try{throw new Error('stacktrace')}
catch(e2){stack.push(...(e2.stack??'').split(/\n/))}
e=new(window[type??'Error']??Error)(msg??'Unspecified error');e.name=type??'Error';}
for(let i=0;i<stack.length;i++){const frame=stack[i].replace(/(.*?)@(.+):(\d+):(\d+)/g,'at $1 ($2:$3:$4)').trim();stack[i]=frame?`  ${frame}`:'';}
if(!/^  at /.test(stack[0]))
stack.shift();if(/\braise /.test(stack[0]))
stack.shift();if(/\berror /.test(stack[0]))
stack.shift();if(stack.length)
e.message+=`\n${stack.join('\n')}`;if(window.console&&console.debug)
console.debug(e);throw e;},error(type,fmt){try{LuCI.prototype.raise.apply(LuCI.prototype,Array.prototype.slice.call(arguments));}
catch(e){if(!e.reported){if(classes.ui)
classes.ui.addNotification(e.name||_('Runtime error'),E('pre',{},e.message),'danger');else
DOM.content(document.querySelector('#maincontent'),E('pre',{'class':'alert-message error'},e.message));e.reported=true;}
throw e;}},bind(fn,self,...args){return Function.prototype.bind.call(fn,self,...args);},require(name,from=[]){const L=this;let url=null;if(classes[name]!=null){if(from.indexOf(name)!=-1)
LuCI.prototype.raise('DependencyError','Circular dependency: class "%s" depends on "%s"',name,from.join('" which depends on "'));return Promise.resolve(classes[name]);}
url='%s/%s.js%s'.format(env.base_url,name.replace(/\./g,'/'),(env.resource_version?`?v=${env.resource_version}`:''));from=[name].concat(from);const compileClass=res=>{if(!res.ok)
LuCI.prototype.raise('NetworkError','HTTP error %d while loading class file "%s"',res.status,url);const source=res.text();const requirematch=/^require[ \t]+(\S+)(?:[ \t]+as[ \t]+([a-zA-Z_]\S*))?$/;const strictmatch=/^use[ \t]+strict$/;const depends=[];let args='';for(let i=0,off=-1,prev=-1,quote=-1,comment=-1,esc=false;i<source.length;i++){const chr=source.charCodeAt(i);if(esc){esc=false;}
else if(comment!=-1){if((comment==47&&chr==10)||(comment==42&&prev==42&&chr==47))
comment=-1;}
else if((chr==42||chr==47)&&prev==47){comment=chr;}
else if(chr==92){esc=true;}
else if(chr==quote){const s=source.substring(off,i),m=requirematch.exec(s);if(m){const dep=m[1],as=m[2]||dep.replace(/[^a-zA-Z0-9_]/g,'_');depends.push(LuCI.prototype.require(dep,from));args+=`, ${as}`;}
else if(!strictmatch.exec(s)){break;}
off=-1;quote=-1;}
else if(quote==-1&&(chr==34||chr==39)){off=i+1;quote=chr;}
prev=chr;}
return Promise.all(depends).then(instances=>{let _factory,_class;try{_factory=eval('(function(window, document, L%s) { %s })\n\n//# sourceURL=%s\n'.format(args,source,res.url));}
catch(error){LuCI.prototype.raise('SyntaxError','%s\n  in %s:%s',error.message,res.url,error.lineNumber??'?');}
_factory.displayName=toCamelCase(`${name}ClassFactory`);_class=_factory.apply(_factory,[window,document,L].concat(instances));if(!Class.isSubclass(_class))
LuCI.prototype.error('TypeError','"%s" factory yields invalid constructor',name);if(_class.displayName=='AnonymousClass')
_class.displayName=toCamelCase(`${name}Class`);let ptr=Object.getPrototypeOf(L);let idx=0;const parts=name.split(/\./);const instance=new _class();while(ptr&&idx<parts.length-1)
ptr=ptr[parts[idx++]];if(ptr)
ptr[parts[idx]]=instance;classes[name]=instance;return instance;});};classes[name]=Request.get(url,{cache:true}).then(compileClass);return classes[name];},probeRPCBaseURL(){if(rpcBaseURL==null)
rpcBaseURL=Session.getLocalData('rpcBaseURL');if(rpcBaseURL==null){const msg={jsonrpc:'2.0',id:'init',method:'list',params:undefined};const rpcFallbackURL=this.url('admin/ubus');rpcBaseURL=Request.post(env.ubuspath,msg,{nobatch:true}).then(res=>rpcBaseURL=res.status==200?env.ubuspath:rpcFallbackURL,()=>rpcBaseURL=rpcFallbackURL).then(url=>{Session.setLocalData('rpcBaseURL',url);return url;});}
return Promise.resolve(rpcBaseURL);},probeSystemFeatures(){if(sysFeatures==null)
sysFeatures=Session.getLocalData('features');if(!this.isObject(sysFeatures)){sysFeatures=classes.rpc.declare({object:'luci',method:'getFeatures',expect:{'':{}}})().then(features=>{Session.setLocalData('features',features);sysFeatures=features;return features;});}
return Promise.resolve(sysFeatures);},probePreloadClasses(){if(preloadClasses==null)
preloadClasses=Session.getLocalData('preload');if(!Array.isArray(preloadClasses)){preloadClasses=this.resolveDefault(classes.rpc.declare({object:'file',method:'list',params:['path'],expect:{'entries':[]}})(this.fspath(this.resource('preload'))),[]).then(entries=>{const classes=[];for(let i=0;i<entries.length;i++){if(entries[i].type!='file')
continue;const m=entries[i].name.match(/(.+)\.js$/);if(m)
classes.push('preload.%s'.format(m[1]));}
Session.setLocalData('preload',classes);preloadClasses=classes;return classes;});}
return Promise.resolve(preloadClasses);},hasSystemFeature(){const ft=sysFeatures[arguments[0]];if(arguments.length==2)
return this.isObject(ft)?ft[arguments[1]]:null;return(ft!=null&&ft!=false);},notifySessionExpiry(){Poll.stop();classes.ui.showModal(_('Session expired'),[E('div',{class:'alert-message warning'},_('A new login is required since the authentication session expired.')),E('div',{class:'right'},E('div',{class:'btn primary',click(){const loc=window.location;window.location=`${loc.protocol}//${loc.host}${loc.pathname}${loc.search}`;}},_('Log in…')))]);LuCI.prototype.raise('SessionError','Login session is expired');},setupDOM([domEv,uiClass,rpcClass,formClass,rpcBaseURL]){rpcClass.setBaseURL(rpcBaseURL);rpcClass.addInterceptor((msg,req)=>{if(!LuCI.prototype.isObject(msg)||!LuCI.prototype.isObject(msg.error)||msg.error.code!=-32002)
return;if(!LuCI.prototype.isObject(req)||(req.object=='session'&&req.method=='access'))
return;return rpcClass.declare({'object':'session','method':'access','params':['scope','object','function'],'expect':{access:true}})('uci','luci','read').catch(LuCI.prototype.notifySessionExpiry);});Request.addInterceptor(res=>{let isDenied=false;if(res.status==403&&res.headers.get('X-LuCI-Login-Required')=='yes')
isDenied=true;if(!isDenied)
return;LuCI.prototype.notifySessionExpiry();});document.addEventListener('poll-start',ev=>{uiClass.showIndicator('poll-status',_('Refreshing'),ev=>{Request.poll.active()?Request.poll.stop():Request.poll.start();});});document.addEventListener('poll-stop',ev=>{uiClass.showIndicator('poll-status',_('Paused'),null,'inactive');});return Promise.all([this.probeSystemFeatures(),this.probePreloadClasses()]).finally(LuCI.prototype.bind(function(){const tasks=[];if(Array.isArray(preloadClasses))
for(let i=0;i<preloadClasses.length;i++)
tasks.push(this.require(preloadClasses[i]));return Promise.all(tasks);},this)).finally(this.initDOM);},initDOM(){originalCBIInit();Poll.start();L.loaded=true;document.dispatchEvent(new CustomEvent('luci-loaded'));},loaded:false,env,fspath(){let path=env.documentroot;for(let i=0;i<arguments.length;i++)
path+=`/${arguments[i]}`;const p=path.replace(/\/+$/,'').replace(/\/+/g,'/').split(/\//),res=[];for(let i=0;i<p.length;i++)
if(p[i]=='..')
res.pop();else if(p[i]!='.')
res.push(p[i]);return res.join('/');},path(prefix='',parts){const url=[prefix];for(let i=0;i<parts.length;i++){const part=parts[i];if(Array.isArray(part))
url.push(this.path('',part));else
if(/^(?:[a-zA-Z0-9_.%,;-]+\/)*[a-zA-Z0-9_.%,;-]+$/.test(part)||/^\?[a-zA-Z0-9_.%=&;-]+$/.test(part))
url.push(part.startsWith('?')?part:'/'+part);}
if(url.length===1)
url.push('/');return url.join('');},url(){return this.path(env.scriptname,arguments);},resource(){return this.path(env.resource,arguments);},media(){return this.path(env.media,arguments);},location(){return this.path(env.scriptname,env.requestpath);},isObject(val){return(val!=null&&typeof(val)=='object');},isArguments(val){return(Object.prototype.toString.call(val)=='[object Arguments]');},sortedKeys(obj,key,sortmode){if(obj==null||typeof(obj)!='object')
return[];return Object.keys(obj).map(e=>{let v=(key!=null)?obj[e][key]:e;switch(sortmode){case'addr':v=(v!=null)?v.replace(/(?:^|[.:])([0-9a-fA-F]{1,4})/g,(m0,m1)=>(`000${m1.toLowerCase()}`).substr(-4)):null;break;case'num':v=(v!=null)?+v:null;break;}
return[e,v];}).filter(e=>e[1]!=null).sort((a,b)=>naturalCompare(a[1],b[1])).map(e=>e[0]);},naturalCompare,sortedArray(val){return this.toArray(val).sort(naturalCompare);},toArray(val){if(val==null)
return[];else if(Array.isArray(val))
return val;else if(typeof(val)=='object')
return[val];const s=String(val).trim();if(s=='')
return[];return s.split(/\s+/);},resolveDefault(value,defvalue){return Promise.resolve(value).catch(()=>defvalue);},get(url,args,cb){return this.poll(null,url,args,cb,false);},post(url,args,cb){return this.poll(null,url,args,cb,true);},poll(interval,url,args,cb,post){if(interval!==null&&interval<=0)
interval=env.pollinterval;const data=Object.assign(post?{token:env.token}:{},args);const method=post?'POST':'GET';if(!/^(?:\/|\S+:\/\/)/.test(url))
url=this.url(url);if(interval!==null)
return Request.poll.add(interval,url,{method,query:data},cb);else
return Request.request(url,{method,query:data}).then(res=>{let json=null;if(/^application\/json\b/.test(res.headers.get('Content-Type')))
try{json=res.json()}catch(e){}
cb(res.xhr,json,res.duration);});},hasViewPermission(){if(!this.isObject(env.nodespec)||!env.nodespec.satisfied)
return null;return!env.nodespec.readonly;},stop(entry){return Poll.remove(entry)},halt(){return Poll.stop()},run(){return Poll.start()},dom:DOM,view:View,Poll,Request,Class});const XHR=Class.extend({__name__:'LuCI.xhr',__init__(){if(window.console&&console.debug)
console.debug('Direct use XHR() is deprecated, please use L.Request instead');},_response(cb,res,json,duration){if(this.active)
cb(res,json,duration);delete this.active;},get(url,data,callback,timeout){this.active=true;LuCI.prototype.get(url,data,this._response.bind(this,callback),timeout);},post(url,data,callback,timeout){this.active=true;LuCI.prototype.post(url,data,this._response.bind(this,callback),timeout);},cancel(){delete this.active},busy(){return(this.active===true)},abort(){},send_form(){LuCI.prototype.error('InternalError','Not implemented')},});XHR.get=(...args)=>LuCI.prototype.get.call(LuCI.prototype,...args);XHR.post=(...args)=>LuCI.prototype.post.call(LuCI.prototype,...args);XHR.poll=(...args)=>LuCI.prototype.poll.call(LuCI.prototype,...args);XHR.stop=Request.poll.remove.bind(Request.poll);XHR.halt=Request.poll.stop.bind(Request.poll);XHR.run=Request.poll.start.bind(Request.poll);XHR.running=Request.poll.active.bind(Request.poll);window.XHR=XHR;window.LuCI=LuCI;})(window,document);