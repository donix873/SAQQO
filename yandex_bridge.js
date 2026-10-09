// Browser-only fallback uses the public JavaScript API key, never server keys.
(() => {
  let loaded;
  function ready(key) {
    if (!loaded) loaded = new Promise((resolve,reject) => {
      const script=document.createElement('script');
      script.src='https://api-maps.yandex.ru/2.1/?apikey='+encodeURIComponent(key)+'&lang=ru_RU';
      script.onload=()=>window.ymaps.ready(resolve);script.onerror=reject;
      document.head.appendChild(script);
    });
    return loaded;
  }
  window.saqgoYandexGeocode=async(key,query)=>{
    await ready(key);
    const text=/аркалык|арқалық|arkalyk/i.test(query)?query:query+', Аркалык, Казахстан';
    const response=await ymaps.geocode(text,{boundedBy:[[50.05,66.45],[50.48,67.38]],strictBounds:true,results:3});
    const results=[];
    response.geoObjects.each(place=>{
      const point=place.geometry.getCoordinates();
      if(point[0]>=50.05&&point[0]<=50.48&&point[1]>=66.45&&point[1]<=67.38)
        results.push({name:place.properties.get('text'),point:{latitude:point[0],longitude:point[1]}});
    });
    return JSON.stringify({results});
  };
  window.saqgoYandexRoutes=async(key,from,to,mode)=>{
    await ready(key);
    return new Promise((resolve,reject)=>{
      const route=new ymaps.multiRouter.MultiRoute({referencePoints:[JSON.parse(from),JSON.parse(to)],params:{routingMode:mode==='walking'?'pedestrian':'auto',results:3}},{});
      const timeout=setTimeout(()=>reject(new Error('route timeout')),15000);
      route.model.events.add('requestfail',()=>{clearTimeout(timeout);reject(new Error('route unavailable'));});
      route.model.events.add('requestsuccess',()=>{
        clearTimeout(timeout);const routes=[];
        route.getRoutes().each(item=>{
          const points=[];
          item.getPaths().each(path=>path.getSegments().each(segment=>{
            for(const point of segment.geometry.getCoordinates()) points.push(point);
          }));
          routes.push({legs:[{status:'OK',steps:[{length:item.properties.get('distance').value,duration:item.properties.get('duration').value,polyline:{points}}]}]});
        });
        resolve(JSON.stringify({routes}));
      });
    });
  };
})();
