(_=>{
var v,d=document,q='querySelector',t=m=>(v=d.createElement('template'),v.innerHTML=m,v.content);
this.$=m=>({'<':t,'#':d[q]}[m[0]]||d[q+'All']).call(d,m)
})()