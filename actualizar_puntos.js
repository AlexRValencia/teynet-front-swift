const fs = require('fs');
const data = JSON.parse(fs.readFileSync('data.json'));
const puntos = JSON.parse(fs.readFileSync('puntos_mongodb.json'));
const dataMap = new Map();
data.forEach(item => { dataMap.set(item.name, item.type); });
let modified = 0;
puntos.forEach(punto => {
  if (dataMap.has(punto.name) && punto.type !== dataMap.get(punto.name)) {
    const oldType = punto.type;
    punto.type = dataMap.get(punto.name);
    modified++;
    console.log(`Actualizado: ${punto.name} de ${oldType} a ${punto.type}`);
  }
});
fs.writeFileSync('puntos_mongodb_updated.json', JSON.stringify(puntos, null, 2));
console.log(`
Se actualizaron ${modified} puntos en total. Archivo guardado como puntos_mongodb_updated.json`);
