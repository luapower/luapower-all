/*!
* TableSorter 2.14.4 min - Client-side table sorting with ease!
* Copyright (c) 2007 Christian Bach
*/
!function(g){g.extend({tablesorter:new function(){function c(){var a=1<arguments.length?Array.prototype.slice.call(arguments):arguments[0];"undefined"!==typeof console&&"undefined"!==typeof console.log?console.log(a):alert(a)}function r(a,b){c(a+" ("+((new Date).getTime()-b.getTime())+"ms)")}function k(a){for(var b in a)return!1;return!0}function p(a,b,d){if(!b)return"";var h=a.config,e=h.textExtraction,n="",n="simple"===e?h.supportsTextContent?b.textContent:g(b).text():"function"===typeof e?e(b, a,d):"object"===typeof e&&e.hasOwnProperty(d)?e[d](b,a,d):h.supportsTextContent?b.textContent:g(b).text();return g.trim(n)}function s(a){var b=a.config,d=b.$tbodies=b.$table.children("tbody:not(."+b.cssInfoBlock+")"),h,e,n,l,x,g,m,v="";if(0===d.length)return b.debug?c("*Empty table!* Not building a parser cache"):"";b.debug&&(m=new Date,c("Detecting parsers for each column"));d=d[0].rows;if(d[0])for(h=[],e=d[0].cells.length,n=0;n<e;n++){l=b.$headers.filter(":not([colspan])");l=l.add(b.$headers.filter('[colspan="1"]')).filter('[data-column="'+ n+'"]:last');x=b.headers[n];g=f.getParserById(f.getData(l,x,"sorter"));b.empties[n]=f.getData(l,x,"empty")||b.emptyTo||(b.emptyToBottom?"bottom":"top");b.strings[n]=f.getData(l,x,"string")||b.stringTo||"max";if(!g)a:{l=a;x=d;g=-1;for(var k=n,u=void 0,A=f.parsers.length,q=!1,s="",u=!0;""===s&&u;)g++,x[g]?(q=x[g].cells[k],s=p(l,q,k),l.config.debug&&c("Checking if value was empty on row "+g+", column: "+k+': "'+s+'"')):u=!1;for(;0<=--A;)if((u=f.parsers[A])&&"text"!==u.id&&u.is&&u.is(s,l,q)){g=u;break a}g= f.getParserById("text")}b.debug&&(v+="column:"+n+"; parser:"+g.id+"; string:"+b.strings[n]+"; empty: "+b.empties[n]+"\n");h.push(g)}b.debug&&(c(v),r("Completed detecting parsers",m));b.parsers=h}function w(a){var b=a.tBodies,d=a.config,h,e,n=d.parsers,l,x,y,m,v,k,u,A=[];d.cache={};if(!n)return d.debug?c("*Empty table!* Not building a cache"):"";d.debug&&(u=new Date);d.showProcessing&&f.isProcessing(a,!0);for(m=0;m<b.length;m++)if(d.cache[m]={row:[],normalized:[]},!g(b[m]).hasClass(d.cssInfoBlock)){h= b[m]&&b[m].rows.length||0;e=b[m].rows[0]&&b[m].rows[0].cells.length||0;for(x=0;x<h;++x)if(v=g(b[m].rows[x]),k=[],v.hasClass(d.cssChildRow))d.cache[m].row[d.cache[m].row.length-1]=d.cache[m].row[d.cache[m].row.length-1].add(v);else{d.cache[m].row.push(v);for(y=0;y<e;++y)l=p(a,v[0].cells[y],y),l=n[y].format(l,a,v[0].cells[y],y),k.push(l),"numeric"===(n[y].type||"").toLowerCase()&&(A[y]=Math.max(Math.abs(l)||0,A[y]||0));k.push(d.cache[m].normalized.length);d.cache[m].normalized.push(k)}d.cache[m].colMax= A}d.showProcessing&&f.isProcessing(a);d.debug&&r("Building cache for "+h+" rows",u)}function z(a,b){var d=a.config,h=d.widgetOptions,e=a.tBodies,n=[],l=d.cache,c,y,m,v,p,u,A,q,s,t,w;if(!k(l)){d.debug&&(w=new Date);for(q=0;q<e.length;q++)if(c=g(e[q]),c.length&&!c.hasClass(d.cssInfoBlock)){p=f.processTbody(a,c,!0);c=l[q].row;y=l[q].normalized;v=(m=y.length)?y[0].length-1:0;for(u=0;u<m;u++)if(t=y[u][v],n.push(c[t]),!d.appender||d.pager&&!(d.pager.removeRows&&h.pager_removeRows||d.pager.ajax))for(s=c[t].length, A=0;A<s;A++)p.append(c[t][A]);f.processTbody(a,p,!1)}d.appender&&d.appender(a,n);d.debug&&r("Rebuilt table",w);b||d.appender||f.applyWidget(a);g(a).trigger("sortEnd",a);g(a).trigger("updateComplete",a)}}function D(a){var b=[],d={},h=0,e=g(a).find("thead:eq(0), tfoot").children("tr"),n,l,c,f,m,k,r,p,t,q;for(n=0;n<e.length;n++)for(m=e[n].cells,l=0;l<m.length;l++){f=m[l];k=f.parentNode.rowIndex;r=k+"-"+f.cellIndex;p=f.rowSpan||1;t=f.colSpan||1;"undefined"===typeof b[k]&&(b[k]=[]);for(c=0;c<b[k].length+ 1;c++)if("undefined"===typeof b[k][c]){q=c;break}d[r]=q;h=Math.max(q,h);g(f).attr({"data-column":q});for(c=k;c<k+p;c++)for("undefined"===typeof b[c]&&(b[c]=[]),r=b[c],f=q;f<q+t;f++)r[f]="x"}a.config.columns=h+1;return d}function C(a){return/^d/i.test(a)||1===a}function E(a){var b=D(a),d,h,e,n,l,x,k,m=a.config;m.headerList=[];m.headerContent=[];m.debug&&(k=new Date);n=m.cssIcon?'<i class="'+(m.cssIcon===f.css.icon?f.css.icon:m.cssIcon+" "+f.css.icon)+'"></i>':"";m.$headers=g(a).find(m.selectorHeaders).each(function(a){h= g(this);d=m.headers[a];m.headerContent[a]=g(this).html();l=m.headerTemplate.replace(/\{content\}/g,g(this).html()).replace(/\{icon\}/g,n);m.onRenderTemplate&&(e=m.onRenderTemplate.apply(h,[a,l]))&&"string"===typeof e&&(l=e);g(this).html('<div class="tablesorter-header-inner">'+l+"</div>");m.onRenderHeader&&m.onRenderHeader.apply(h,[a]);this.column=b[this.parentNode.rowIndex+"-"+this.cellIndex];this.order=C(f.getData(h,d,"sortInitialOrder")||m.sortInitialOrder)?[1,0,2]:[0,1,2];this.count=-1;this.lockedOrder= !1;x=f.getData(h,d,"lockedOrder")||!1;"undefined"!==typeof x&&!1!==x&&(this.order=this.lockedOrder=C(x)?[1,1,1]:[0,0,0]);h.addClass(f.css.header+" "+m.cssHeader);m.headerList[a]=this;h.parent().addClass(f.css.headerRow+" "+m.cssHeaderRow);m.tabIndex&&h.attr("tabindex",0)});F(a);m.debug&&(r("Built headers:",k),c(m.$headers))}function B(a,b,d){var h=a.config;h.$table.find(h.selectorRemove).remove();s(a);w(a);G(h.$table,b,d)}function F(a){var b,d=a.config;d.$headers.each(function(a,e){b="false"===f.getData(e, d.headers[a],"sorter");e.sortDisabled=b;g(e)[b?"addClass":"removeClass"]("sorter-false")})}function H(a){var b,d,h,e=a.config,n=e.sortList,l=[f.css.sortAsc+" "+e.cssAsc,f.css.sortDesc+" "+e.cssDesc],c=g(a).find("tfoot tr").children().removeClass(l.join(" "));e.$headers.removeClass(l.join(" "));h=n.length;for(b=0;b<h;b++)if(2!==n[b][1]&&(a=e.$headers.not(".sorter-false").filter('[data-column="'+n[b][0]+'"]'+(1===h?":last":"")),a.length))for(d=0;d<a.length;d++)a[d].sortDisabled||(a.eq(d).addClass(l[n[b][1]]), c.length&&c.filter('[data-column="'+n[b][0]+'"]').eq(d).addClass(l[n[b][1]]))}function L(a){if(a.config.widthFixed&&0===g(a).find("colgroup").length){var b=g("<colgroup>"),d=g(a).width();g(a.tBodies[0]).find("tr:first").children("td:visible").each(function(){b.append(g("<col>").css("width",parseInt(g(this).width()/d*1E3,10)/10+"%"))});g(a).prepend(b)}}function M(a,b){var d,h,e,n=a.config,c=b||n.sortList;n.sortList=[];g.each(c,function(a,b){d=[parseInt(b[0],10),parseInt(b[1],10)];if(e=n.$headers[d[0]])n.sortList.push(d), h=g.inArray(d[1],e.order),e.count=0<=h?h:d[1]%(n.sortReset?3:2)})}function N(a,b){return a&&a[b]?a[b].type||"":""}function O(a,b,d){var h,e,n,c=a.config,x=!d[c.sortMultiSortKey],k=g(a);k.trigger("sortStart",a);b.count=d[c.sortResetKey]?2:(b.count+1)%(c.sortReset?3:2);c.sortRestart&&(e=b,c.$headers.each(function(){this===e||!x&&g(this).is("."+f.css.sortDesc+",."+f.css.sortAsc)||(this.count=-1)}));e=b.column;if(x){c.sortList=[];if(null!==c.sortForce)for(h=c.sortForce,d=0;d<h.length;d++)h[d][0]!==e&& c.sortList.push(h[d]);h=b.order[b.count];if(2>h&&(c.sortList.push([e,h]),1<b.colSpan))for(d=1;d<b.colSpan;d++)c.sortList.push([e+d,h])}else if(c.sortAppend&&1<c.sortList.length&&f.isValueInArray(c.sortAppend[0][0],c.sortList)&&c.sortList.pop(),f.isValueInArray(e,c.sortList))for(d=0;d<c.sortList.length;d++)n=c.sortList[d],h=c.$headers[n[0]],n[0]===e&&(n[1]=h.order[b.count],2===n[1]&&(c.sortList.splice(d,1),h.count=-1));else if(h=b.order[b.count],2>h&&(c.sortList.push([e,h]),1<b.colSpan))for(d=1;d< b.colSpan;d++)c.sortList.push([e+d,h]);if(null!==c.sortAppend)for(h=c.sortAppend,d=0;d<h.length;d++)h[d][0]!==e&&c.sortList.push(h[d]);k.trigger("sortBegin",a);setTimeout(function(){H(a);I(a);z(a)},1)}function I(a){var b,d,c,e,n,l,g,p,m,v,t,u,s=0,q=a.config,w=q.textSorter||"",z=q.sortList,B=z.length,C=a.tBodies.length;if(!q.serverSideSorting&&!k(q.cache)){q.debug&&(m=new Date);for(d=0;d<C;d++)n=q.cache[d].colMax,p=(l=q.cache[d].normalized)&&l[0]?l[0].length-1:0,l.sort(function(d,l){for(b=0;b<B;b++){e= z[b][0];g=z[b][1];s=0===g;if(q.sortStable&&d[e]===l[e]&&1===B)break;(c=/n/i.test(N(q.parsers,e)))&&q.strings[e]?(c="boolean"===typeof q.string[q.strings[e]]?(s?1:-1)*(q.string[q.strings[e]]?-1:1):q.strings[e]?q.string[q.strings[e]]||0:0,v=q.numberSorter?q.numberSorter(t[e],u[e],s,n[e],a):f["sortNumeric"+(s?"Asc":"Desc")](d[e],l[e],c,n[e],e,a)):(t=s?d:l,u=s?l:d,v="function"===typeof w?w(t[e],u[e],s,e,a):"object"===typeof w&&w.hasOwnProperty(e)?w[e](t[e],u[e],s,e,a):f["sortNatural"+(s?"Asc":"Desc")](d[e], l[e],e,a,q));if(v)return v}return d[p]-l[p]});q.debug&&r("Sorting on "+z.toString()+" and dir "+g+" time",m)}}function J(a,b){var d=a[0].config;d.pager&&!d.pager.ajax&&a.trigger("updateComplete");"function"===typeof b&&b(a[0])}function G(a,b,d){!1===b||a[0].isProcessing?J(a,d):a.trigger("sorton",[a[0].config.sortList,function(){J(a,d)}])}function K(a){var b=a.config,d=b.$table,c,e;b.$headers.find(b.selectorSort).add(b.$headers.filter(b.selectorSort)).unbind("mousedown.tablesorter mouseup.tablesorter sort.tablesorter keypress.tablesorter").bind("mousedown.tablesorter mouseup.tablesorter sort.tablesorter keypress.tablesorter", function(d,c){if(!(1!==(d.which||d.button)&&!/sort|keypress/.test(d.type)||"keypress"===d.type&&13!==d.which||"mouseup"===d.type&&!0!==c&&250<(new Date).getTime()-e)){if("mousedown"===d.type)return e=(new Date).getTime(),"INPUT"===d.target.tagName?"":!b.cancelSelection;b.delayInit&&k(b.cache)&&w(a);var h=(/TH|TD/.test(this.tagName)?g(this):g(this).parents("th, td").filter(":first"))[0];h.sortDisabled||O(a,h,d)}});b.cancelSelection&&b.$headers.attr("unselectable","on").bind("selectstart",!1).css({"user-select":"none", MozUserSelect:"none"});d.unbind("sortReset update updateRows updateCell updateAll addRows sorton appendCache applyWidgetId applyWidgets refreshWidgets destroy mouseup mouseleave ".split(" ").join(".tablesorter ")).bind("sortReset.tablesorter",function(d){d.stopPropagation();b.sortList=[];H(a);I(a);z(a)}).bind("updateAll.tablesorter",function(b,d,c){b.stopPropagation();f.refreshWidgets(a,!0,!0);f.restoreHeaders(a);E(a);K(a);B(a,d,c)}).bind("update.tablesorter updateRows.tablesorter",function(b,d,c){b.stopPropagation(); F(a);B(a,d,c)}).bind("updateCell.tablesorter",function(c,e,h,f){c.stopPropagation();d.find(b.selectorRemove).remove();var m,k,r;m=d.find("tbody");c=m.index(g(e).parents("tbody").filter(":first"));var s=g(e).parents("tr").filter(":first");e=g(e)[0];m.length&&0<=c&&(k=m.eq(c).find("tr").index(s),r=e.cellIndex,m=b.cache[c].normalized[k].length-1,b.cache[c].row[a.config.cache[c].normalized[k][m]]=s,b.cache[c].normalized[k][r]=b.parsers[r].format(p(a,e,r),a,e,r),G(d,h,f))}).bind("addRows.tablesorter", function(e,f,g,r){e.stopPropagation();if(k(b.cache))F(a),B(a,g,r);else{var m=f.filter("tr").length,v=[],w=f[0].cells.length,u=d.find("tbody").index(f.parents("tbody").filter(":first"));b.parsers||s(a);for(e=0;e<m;e++){for(c=0;c<w;c++)v[c]=b.parsers[c].format(p(a,f[e].cells[c],c),a,f[e].cells[c],c);v.push(b.cache[u].row.length);b.cache[u].row.push([f[e]]);b.cache[u].normalized.push(v);v=[]}G(d,g,r)}}).bind("sorton.tablesorter",function(b,c,e,h){var f=a.config;b.stopPropagation();d.trigger("sortStart", this);M(a,c);H(a);f.delayInit&&k(f.cache)&&w(a);d.trigger("sortBegin",this);I(a);z(a,h);"function"===typeof e&&e(a)}).bind("appendCache.tablesorter",function(b,d,c){b.stopPropagation();z(a,c);"function"===typeof d&&d(a)}).bind("applyWidgetId.tablesorter",function(d,c){d.stopPropagation();f.getWidgetById(c).format(a,b,b.widgetOptions)}).bind("applyWidgets.tablesorter",function(b,d){b.stopPropagation();f.applyWidget(a,d)}).bind("refreshWidgets.tablesorter",function(b,d,c){b.stopPropagation();f.refreshWidgets(a, d,c)}).bind("destroy.tablesorter",function(b,d,c){b.stopPropagation();f.destroy(a,d,c)})}var f=this;f.version="2.14.4";f.parsers=[];f.widgets=[];f.defaults={theme:"default",widthFixed:!1,showProcessing:!1,headerTemplate:"{content}",onRenderTemplate:null,onRenderHeader:null,cancelSelection:!0,tabIndex:!0,dateFormat:"mmddyyyy",sortMultiSortKey:"shiftKey",sortResetKey:"ctrlKey",usNumberFormat:!0,delayInit:!1,serverSideSorting:!1,headers:{},ignoreCase:!0,sortForce:null,sortList:[],sortAppend:null,sortStable:!1, sortInitialOrder:"asc",sortLocaleCompare:!1,sortReset:!1,sortRestart:!1,emptyTo:"bottom",stringTo:"max",textExtraction:"simple",textSorter:null,numberSorter:null,widgets:[],widgetOptions:{zebra:["even","odd"]},initWidgets:!0,initialized:null,tableClass:"",cssAsc:"",cssDesc:"",cssHeader:"",cssHeaderRow:"",cssProcessing:"",cssChildRow:"tablesorter-childRow",cssIcon:"tablesorter-icon",cssInfoBlock:"tablesorter-infoOnly",selectorHeaders:"> thead th, > thead td",selectorSort:"th, td",selectorRemove:".remove-me", debug:!1,headerList:[],empties:{},strings:{},parsers:[]};f.css={table:"tablesorter",childRow:"tablesorter-childRow",header:"tablesorter-header",headerRow:"tablesorter-headerRow",icon:"tablesorter-icon",info:"tablesorter-infoOnly",processing:"tablesorter-processing",sortAsc:"tablesorter-headerAsc",sortDesc:"tablesorter-headerDesc"};f.log=c;f.benchmark=r;f.construct=function(a){return this.each(function(){var b=g.extend(!0,{},f.defaults,a);!this.hasInitialized&&f.buildTable&&"TABLE"!==this.tagName&& f.buildTable(this,b);f.setup(this,b)})};f.setup=function(a,b){if(!a||!a.tHead||0===a.tBodies.length||!0===a.hasInitialized)return b.debug?c("stopping initialization! No table, thead, tbody or tablesorter has already been initialized"):"";var d="",h=g(a),e=g.metadata;a.hasInitialized=!1;a.isProcessing=!0;a.config=b;g.data(a,"tablesorter",b);b.debug&&g.data(a,"startoveralltimer",new Date);b.supportsTextContent="x"===g("<span>x</span>")[0].textContent;b.supportsDataObject=function(a){a[0]=parseInt(a[0], 10);return 1<a[0]||1===a[0]&&4<=parseInt(a[1],10)}(g.fn.jquery.split("."));b.string={max:1,min:-1,"max+":1,"max-":-1,zero:0,none:0,"null":0,top:!0,bottom:!1};/tablesorter\-/.test(h.attr("class"))||(d=""!==b.theme?" tablesorter-"+b.theme:"");b.$table=h.addClass(f.css.table+" "+b.tableClass+d);b.$tbodies=h.children("tbody:not(."+b.cssInfoBlock+")");b.widgetInit={};E(a);L(a);s(a);b.delayInit||w(a);K(a);b.supportsDataObject&&"undefined"!==typeof h.data().sortlist?b.sortList=h.data().sortlist:e&&h.metadata()&& h.metadata().sortlist&&(b.sortList=h.metadata().sortlist);f.applyWidget(a,!0);0<b.sortList.length?h.trigger("sorton",[b.sortList,{},!b.initWidgets]):b.initWidgets&&f.applyWidget(a);b.showProcessing&&h.unbind("sortBegin.tablesorter sortEnd.tablesorter").bind("sortBegin.tablesorter sortEnd.tablesorter",function(b){f.isProcessing(a,"sortBegin"===b.type)});a.hasInitialized=!0;a.isProcessing=!1;b.debug&&f.benchmark("Overall initialization time",g.data(a,"startoveralltimer"));h.trigger("tablesorter-initialized", a);"function"===typeof b.initialized&&b.initialized(a)};f.isProcessing=function(a,b,d){a=g(a);var c=a[0].config;a=d||a.find("."+f.css.header);b?(0<c.sortList.length&&(a=a.filter(function(){return this.sortDisabled?!1:f.isValueInArray(parseFloat(g(this).attr("data-column")),c.sortList)})),a.addClass(f.css.processing+" "+c.cssProcessing)):a.removeClass(f.css.processing+" "+c.cssProcessing)};f.processTbody=function(a,b,d){if(d)return a.isProcessing=!0,b.before('<span class="tablesorter-savemyplace"/>'), d=g.fn.detach?b.detach():b.remove();d=g(a).find("span.tablesorter-savemyplace");b.insertAfter(d);d.remove();a.isProcessing=!1};f.clearTableBody=function(a){g(a)[0].config.$tbodies.empty()};f.restoreHeaders=function(a){var b=a.config;b.$table.find(b.selectorHeaders).each(function(a){g(this).find(".tablesorter-header-inner").length&&g(this).html(b.headerContent[a])})};f.destroy=function(a,b,d){a=g(a)[0];if(a.hasInitialized){f.refreshWidgets(a,!0,!0);var c=g(a),e=a.config,n=c.find("thead:first"),l=n.find("tr."+ f.css.headerRow).removeClass(f.css.headerRow+" "+e.cssHeaderRow),k=c.find("tfoot:first > tr").children("th, td");n.find("tr").not(l).remove();c.removeData("tablesorter").unbind("sortReset update updateAll updateRows updateCell addRows sorton appendCache applyWidgetId applyWidgets refreshWidgets destroy mouseup mouseleave keypress sortBegin sortEnd ".split(" ").join(".tablesorter "));e.$headers.add(k).removeClass([f.css.header,e.cssHeader,e.cssAsc,e.cssDesc,f.css.sortAsc,f.css.sortDesc].join(" ")).removeAttr("data-column"); l.find(e.selectorSort).unbind("mousedown.tablesorter mouseup.tablesorter keypress.tablesorter");f.restoreHeaders(a);!1!==b&&c.removeClass(f.css.table+" "+e.tableClass+" tablesorter-"+e.theme);a.hasInitialized=!1;"function"===typeof d&&d(a)}};f.regex={chunk:/(^([+\-]?(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+\-]?\d+)?)?$|^0x[0-9a-f]+$|\d+)/gi,hex:/^0x[0-9a-f]+$/i};f.sortNatural=function(a,b){if(a===b)return 0;var d,c,e,g,l,k;c=f.regex;if(c.hex.test(b)){d=parseInt(a.match(c.hex),16);e=parseInt(b.match(c.hex), 16);if(d<e)return-1;if(d>e)return 1}d=a.replace(c.chunk,"\\0$1\\0").replace(/\\0$/,"").replace(/^\\0/,"").split("\\0");c=b.replace(c.chunk,"\\0$1\\0").replace(/\\0$/,"").replace(/^\\0/,"").split("\\0");k=Math.max(d.length,c.length);for(l=0;l<k;l++){e=isNaN(d[l])?d[l]||0:parseFloat(d[l])||0;g=isNaN(c[l])?c[l]||0:parseFloat(c[l])||0;if(isNaN(e)!==isNaN(g))return isNaN(e)?1:-1;typeof e!==typeof g&&(e+="",g+="");if(e<g)return-1;if(e>g)return 1}return 0};f.sortNaturalAsc=function(a,b,d,c,e){if(a===b)return 0; d=e.string[e.empties[d]||e.emptyTo];return""===a&&0!==d?"boolean"===typeof d?d?-1:1:-d||-1:""===b&&0!==d?"boolean"===typeof d?d?1:-1:d||1:f.sortNatural(a,b)};f.sortNaturalDesc=function(a,b,d,c,e){if(a===b)return 0;d=e.string[e.empties[d]||e.emptyTo];return""===a&&0!==d?"boolean"===typeof d?d?-1:1:d||1:""===b&&0!==d?"boolean"===typeof d?d?1:-1:-d||-1:f.sortNatural(b,a)};f.sortText=function(a,b){return a>b?1:a<b?-1:0};f.getTextValue=function(a,b,d){if(d){var c=a?a.length:0,e=d+b;for(d=0;d<c;d++)e+= a.charCodeAt(d);return b*e}return 0};f.sortNumericAsc=function(a,b,d,c,e,g){if(a===b)return 0;g=g.config;e=g.string[g.empties[e]||g.emptyTo];if(""===a&&0!==e)return"boolean"===typeof e?e?-1:1:-e||-1;if(""===b&&0!==e)return"boolean"===typeof e?e?1:-1:e||1;isNaN(a)&&(a=f.getTextValue(a,d,c));isNaN(b)&&(b=f.getTextValue(b,d,c));return a-b};f.sortNumericDesc=function(a,b,d,c,e,g){if(a===b)return 0;g=g.config;e=g.string[g.empties[e]||g.emptyTo];if(""===a&&0!==e)return"boolean"===typeof e?e?-1:1:e||1;if(""=== b&&0!==e)return"boolean"===typeof e?e?1:-1:-e||-1;isNaN(a)&&(a=f.getTextValue(a,d,c));isNaN(b)&&(b=f.getTextValue(b,d,c));return b-a};f.sortNumeric=function(a,b){return a-b};f.characterEquivalents={a:"\u00e1\u00e0\u00e2\u00e3\u00e4\u0105\u00e5",A:"\u00c1\u00c0\u00c2\u00c3\u00c4\u0104\u00c5",c:"\u00e7\u0107\u010d",C:"\u00c7\u0106\u010c",e:"\u00e9\u00e8\u00ea\u00eb\u011b\u0119",E:"\u00c9\u00c8\u00ca\u00cb\u011a\u0118",i:"\u00ed\u00ec\u0130\u00ee\u00ef\u0131",I:"\u00cd\u00cc\u0130\u00ce\u00cf",o:"\u00f3\u00f2\u00f4\u00f5\u00f6", O:"\u00d3\u00d2\u00d4\u00d5\u00d6",ss:"\u00df",SS:"\u1e9e",u:"\u00fa\u00f9\u00fb\u00fc\u016f",U:"\u00da\u00d9\u00db\u00dc\u016e"};f.replaceAccents=function(a){var b,d="[",c=f.characterEquivalents;if(!f.characterRegex){f.characterRegexArray={};for(b in c)"string"===typeof b&&(d+=c[b],f.characterRegexArray[b]=RegExp("["+c[b]+"]","g"));f.characterRegex=RegExp(d+"]")}if(f.characterRegex.test(a))for(b in c)"string"===typeof b&&(a=a.replace(f.characterRegexArray[b],b));return a};f.isValueInArray=function(a, b){var d,c=b.length;for(d=0;d<c;d++)if(b[d][0]===a)return!0;return!1};f.addParser=function(a){var b,d=f.parsers.length,c=!0;for(b=0;b<d;b++)f.parsers[b].id.toLowerCase()===a.id.toLowerCase()&&(c=!1);c&&f.parsers.push(a)};f.getParserById=function(a){var b,d=f.parsers.length;for(b=0;b<d;b++)if(f.parsers[b].id.toLowerCase()===a.toString().toLowerCase())return f.parsers[b];return!1};f.addWidget=function(a){f.widgets.push(a)};f.getWidgetById=function(a){var b,d,c=f.widgets.length;for(b=0;b<c;b++)if((d= f.widgets[b])&&d.hasOwnProperty("id")&&d.id.toLowerCase()===a.toLowerCase())return d};f.applyWidget=function(a,b){a=g(a)[0];var d=a.config,c=d.widgetOptions,e=[],k,l,p;d.debug&&(k=new Date);d.widgets.length&&(d.widgets=g.grep(d.widgets,function(a,b){return g.inArray(a,d.widgets)===b}),g.each(d.widgets||[],function(a,b){(p=f.getWidgetById(b))&&p.id&&(p.priority||(p.priority=10),e[a]=p)}),e.sort(function(a,b){return a.priority<b.priority?-1:a.priority===b.priority?0:1}),g.each(e,function(e,f){if(f){if(b|| !d.widgetInit[f.id])f.hasOwnProperty("options")&&(c=a.config.widgetOptions=g.extend(!0,{},f.options,c)),f.hasOwnProperty("init")&&f.init(a,f,d,c),d.widgetInit[f.id]=!0;!b&&f.hasOwnProperty("format")&&f.format(a,d,c,!1)}}));d.debug&&(l=d.widgets.length,r("Completed "+(!0===b?"initializing ":"applying ")+l+" widget"+(1!==l?"s":""),k))};f.refreshWidgets=function(a,b,d){a=g(a)[0];var h,e=a.config,k=e.widgets,l=f.widgets,r=l.length;for(h=0;h<r;h++)l[h]&&l[h].id&&(b||0>g.inArray(l[h].id,k))&&(e.debug&& c("Refeshing widgets: Removing "+l[h].id),l[h].hasOwnProperty("remove")&&e.widgetInit[l[h].id]&&(l[h].remove(a,e,e.widgetOptions),e.widgetInit[l[h].id]=!1));!0!==d&&f.applyWidget(a,b)};f.getData=function(a,b,d){var c="";a=g(a);var e,f;if(!a.length)return"";e=g.metadata?a.metadata():!1;f=" "+(a.attr("class")||"");"undefined"!==typeof a.data(d)||"undefined"!==typeof a.data(d.toLowerCase())?c+=a.data(d)||a.data(d.toLowerCase()):e&&"undefined"!==typeof e[d]?c+=e[d]:b&&"undefined"!==typeof b[d]?c+=b[d]: " "!==f&&f.match(" "+d+"-")&&(c=f.match(RegExp("\\s"+d+"-([\\w-]+)"))[1]||"");return g.trim(c)};f.formatFloat=function(a,b){if("string"!==typeof a||""===a)return a;var c;a=(b&&b.config?!1!==b.config.usNumberFormat:"undefined"!==typeof b?b:1)?a.replace(/,/g,""):a.replace(/[\s|\.]/g,"").replace(/,/g,".");/^\s*\([.\d]+\)/.test(a)&&(a=a.replace(/^\s*\(([.\d]+)\)/,"-$1"));c=parseFloat(a);return isNaN(c)?g.trim(a):c};f.isDigit=function(a){return isNaN(a)?/^[\-+(]?\d+[)]?$/.test(a.toString().replace(/[,.'"\s]/g, "")):!0}}});var p=g.tablesorter;g.fn.extend({tablesorter:p.construct});p.addParser({id:"text",is:function(){return!0},format:function(c,r){var k=r.config;c&&(c=g.trim(k.ignoreCase?c.toLocaleLowerCase():c),c=k.sortLocaleCompare?p.replaceAccents(c):c);return c},type:"text"});p.addParser({id:"digit",is:function(c){return p.isDigit(c)},format:function(c,r){var k=p.formatFloat((c||"").replace(/[^\w,. \-()]/g,""),r);return c&&"number"===typeof k?k:c?g.trim(c&&r.config.ignoreCase?c.toLocaleLowerCase():c): c},type:"numeric"});p.addParser({id:"currency",is:function(c){return/^\(?\d+[\u00a3$\u20ac\u00a4\u00a5\u00a2?.]|[\u00a3$\u20ac\u00a4\u00a5\u00a2?.]\d+\)?$/.test((c||"").replace(/[,. ]/g,""))},format:function(c,r){var k=p.formatFloat((c||"").replace(/[^\w,. \-()]/g,""),r);return c&&"number"===typeof k?k:c?g.trim(c&&r.config.ignoreCase?c.toLocaleLowerCase():c):c},type:"numeric"});p.addParser({id:"ipAddress",is:function(c){return/^\d{1,3}[\.]\d{1,3}[\.]\d{1,3}[\.]\d{1,3}$/.test(c)},format:function(c, g){var k,t=c?c.split("."):"",s="",w=t.length;for(k=0;k<w;k++)s+=("00"+t[k]).slice(-3);return c?p.formatFloat(s,g):c},type:"numeric"});p.addParser({id:"url",is:function(c){return/^(https?|ftp|file):\/\//.test(c)},format:function(c){return c?g.trim(c.replace(/(https?|ftp|file):\/\//,"")):c},type:"text"});p.addParser({id:"isoDate",is:function(c){return/^\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}/.test(c)},format:function(c,g){return c?p.formatFloat(""!==c?(new Date(c.replace(/-/g,"/"))).getTime()||"":"",g):c}, type:"numeric"});p.addParser({id:"percent",is:function(c){return/(\d\s*?%|%\s*?\d)/.test(c)&&15>c.length},format:function(c,g){return c?p.formatFloat(c.replace(/%/g,""),g):c},type:"numeric"});p.addParser({id:"usLongDate",is:function(c){return/^[A-Z]{3,10}\.?\s+\d{1,2},?\s+(\d{4})(\s+\d{1,2}:\d{2}(:\d{2})?(\s+[AP]M)?)?$/i.test(c)||/^\d{1,2}\s+[A-Z]{3,10}\s+\d{4}/i.test(c)},format:function(c,g){return c?p.formatFloat((new Date(c.replace(/(\S)([AP]M)$/i,"$1 $2"))).getTime()||"",g):c},type:"numeric"}); p.addParser({id:"shortDate",is:function(c){return/(^\d{1,2}[\/\s]\d{1,2}[\/\s]\d{4})|(^\d{4}[\/\s]\d{1,2}[\/\s]\d{1,2})/.test((c||"").replace(/\s+/g," ").replace(/[\-.,]/g,"/"))},format:function(c,g,k,t){if(c){k=g.config;var s=k.headerList[t];t=s.dateFormat||p.getData(s,k.headers[t],"dateFormat")||k.dateFormat;c=c.replace(/\s+/g," ").replace(/[\-.,]/g,"/");"mmddyyyy"===t?c=c.replace(/(\d{1,2})[\/\s](\d{1,2})[\/\s](\d{4})/,"$3/$1/$2"):"ddmmyyyy"===t?c=c.replace(/(\d{1,2})[\/\s](\d{1,2})[\/\s](\d{4})/, "$3/$2/$1"):"yyyymmdd"===t&&(c=c.replace(/(\d{4})[\/\s](\d{1,2})[\/\s](\d{1,2})/,"$1/$2/$3"))}return c?p.formatFloat((new Date(c)).getTime()||"",g):c},type:"numeric"});p.addParser({id:"time",is:function(c){return/^(([0-2]?\d:[0-5]\d)|([0-1]?\d:[0-5]\d\s?([AP]M)))$/i.test(c)},format:function(c,g){return c?p.formatFloat((new Date("2000/01/01 "+c.replace(/(\S)([AP]M)$/i,"$1 $2"))).getTime()||"",g):c},type:"numeric"});p.addParser({id:"metadata",is:function(){return!1},format:function(c,p,k){c=p.config; c=c.parserMetadataName?c.parserMetadataName:"sortValue";return g(k).metadata()[c]},type:"numeric"});p.addWidget({id:"zebra",priority:90,format:function(c,r,k){var t,s,w,z,D,C,E=RegExp(r.cssChildRow,"i"),B=r.$tbodies;r.debug&&(D=new Date);for(c=0;c<B.length;c++)t=B.eq(c),C=t.children("tr").length,1<C&&(w=0,t=t.children("tr:visible").not(r.selectorRemove),t.each(function(){s=g(this);E.test(this.className)||w++;z=0===w%2;s.removeClass(k.zebra[z?1:0]).addClass(k.zebra[z?0:1])}));r.debug&&p.benchmark("Applying Zebra widget", D)},remove:function(c,p,k){var t;p=p.$tbodies;var s=(k.zebra||["even","odd"]).join(" ");for(k=0;k<p.length;k++)t=g.tablesorter.processTbody(c,p.eq(k),!0),t.children().removeClass(s),g.tablesorter.processTbody(c,t,!1)}})}(jQuery);