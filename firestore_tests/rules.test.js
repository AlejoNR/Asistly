// Pruebas de firestore.rules contra el emulador local (proyecto demo-, sin datos reales).
const fs = require('fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');

const FV = firebase.firestore.FieldValue;
const TS = firebase.firestore.Timestamp;
const now = Date.now();
const SID = 'c1_2026-11-05';

// Hoy en Colombia (UTC-5), como lo calculan las reglas. Lunes = 1 ... domingo = 7.
const bogota = new Date(now - 5 * 3600 * 1000);
const todayKey = bogota.toISOString().substring(0, 10);
const todayNumber = bogota.getUTCDay() === 0 ? 7 : bogota.getUTCDay();
const otherDays = [1, 2, 3, 4, 5, 6, 7].filter((day) => day !== todayNumber);
// Un horario de hoy que ya pasó o todavía no llega (lejos de la hora actual).
const bogotaMinutes = bogota.getUTCHours() * 60 + bogota.getUTCMinutes();
const notNow = bogotaMinutes > 120 ? { inicio: '00:00', fin: '00:30' } : { inicio: '23:00', fin: '23:59' };

function newSession(courseId, extra) {
  return Object.assign({
    cursoId: courseId, docenteId: 'teacher1', fecha: todayKey, numeroClase: 1,
    inicio: FV.serverTimestamp(), fin: null, abierta: true, tiempoRegistro: 10, validarBluetooth: true,
  }, extra);
}

let passed = 0;
let failed = 0;
async function ok(name, fn) {
  try { await assertSucceeds(fn()); passed++; console.log('  ok   ', name); }
  catch (e) { failed++; console.log('  FAIL ', name, '-> debía permitirse:', e.message.split('\n')[0]); }
}
async function no(name, fn) {
  try { await assertFails(fn()); passed++; console.log('  ok   ', name); }
  catch (e) { failed++; console.log('  FAIL ', name, '-> debía rechazarse'); }
}

const students = {
  stu1: { fullName: 'Ana Uno', code: '2024-0001', email: 'stu1@udla.edu.co', deviceId: 'dev1' }, // Lista por código
  stu2: { fullName: 'Beto Dos', code: '2024-0002', email: 'stu2@udla.edu.co', deviceId: 'dev2' }, // Lista por correo
  stu3: { fullName: 'Caro Tres', code: '2024-0003', email: 'stu3@udla.edu.co', deviceId: 'dev3' }, // No está en lista
  stu4: { fullName: 'Dani Cuatro', code: '2024-0004', email: 'stu4@udla.edu.co', deviceId: 'dev4' }, // Lista; retirado
  stu5: { fullName: 'Eva Cinco', code: '2024-0005', email: 'stu5@udla.edu.co', deviceId: 'dev5' }, // Lista; lo retiró el docente
};

function enrollment(uid, extra) {
  const s = students[uid];
  return Object.assign({
    uid, nombre: s.fullName, codigo: s.code, correo: s.email,
    estado: 'pendiente', origen: 'solicitud', fecha: FV.serverTimestamp(), retiradoPor: null,
  }, extra);
}

function attendance(uid, extra) {
  const s = students[uid];
  return Object.assign({
    estado: 'presente', hora: FV.serverTimestamp(), metodo: 'qr', qr: 'AAAA',
    deviceId: s.deviceId, nombre: s.fullName, codigo: s.code,
  }, extra);
}

function report(uid) {
  const s = students[uid];
  return { hora: FV.serverTimestamp(), nombre: s.fullName, codigo: s.code };
}

(async () => {
  const env = await initializeTestEnvironment({
    projectId: 'demo-asistly',
    firestore: { rules: fs.readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8085 },
  });

  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const uid of Object.keys(students)) {
      await db.doc(`users/${uid}`).set(Object.assign({ role: 'student', createdAt: TS.now() }, students[uid]));
    }
    await db.doc('users/teacher1').set({ fullName: 'Prof', code: 'DOC-1', email: 't@udla.edu.co', role: 'teacher', deviceId: null });
    await db.doc('users/teacher2').set({ fullName: 'Otro', code: 'DOC-2', email: 't2@udla.edu.co', role: 'teacher', deviceId: null });

    const course = { nombre: 'PM', docenteId: 'teacher1', codigoInscripcion: 'PM2-4X7K', horaInicio: '00:00', horaFin: '23:59' };
    await db.doc('cursos/c1').set(course);
    await db.doc('cursos/c1/listaOficial/2024-0001').set({ nombre: 'Ana Uno', correo: 'otro@udla.edu.co' });
    await db.doc('cursos/c1/listaOficial/2024-0004').set({ nombre: 'Dani', correo: 'stu4@udla.edu.co' });
    await db.doc('cursos/c1/listaOficial/2024-0005').set({ nombre: 'Eva', correo: 'stu5@udla.edu.co' });
    await db.doc('cursos/c1/listaCorreos/stu2@udla.edu.co').set({});

    await db.doc('cursos/c1/inscripciones/stu4').set(enrollment('stu4', { estado: 'retirado', origen: 'lista', retiradoPor: 'estudiante', fecha: TS.now() }));
    await db.doc('cursos/c1/inscripciones/stu5').set(enrollment('stu5', { estado: 'retirado', origen: 'lista', retiradoPor: 'docente', fecha: TS.now() }));

    const session = { cursoId: 'c1', docenteId: 'teacher1', fecha: '2026-11-05', numeroClase: 1, abierta: true, inicio: TS.fromMillis(now - 60000), tiempoRegistro: 10 };
    await db.doc(`sesiones/${SID}`).set(session);
    await db.doc(`sesiones/${SID}/privado/secreto`).set({ secreto: 'abc' });
    await db.doc(`sesiones/${SID}/privado/tokens`).set({ qrActual: 'AAAA', qrAnterior: 'BBBB', actualizadoEn: TS.now() });

    // Clases para probar los rechazos por tiempo y por estar cerrada.
    await db.doc('sesiones/cerrada').set(Object.assign({}, session, { abierta: false }));
    await db.doc('sesiones/cerrada/privado/tokens').set({ qrActual: 'AAAA', qrAnterior: 'BBBB', actualizadoEn: TS.now() });
    await db.doc('sesiones/vencida').set(Object.assign({}, session, { inicio: TS.fromMillis(now - 11 * 60000) }));
    await db.doc('sesiones/vencida/privado/tokens').set({ qrActual: 'AAAA', qrAnterior: 'BBBB', actualizadoEn: TS.now() });
    await db.doc('sesiones/sinDocente').set(session);
    await db.doc('sesiones/sinDocente/privado/tokens').set({ qrActual: 'AAAA', qrAnterior: 'BBBB', actualizadoEn: TS.fromMillis(now - 5 * 60000) });

    // Cursos para probar el día de clase. Horario de todo el día: solo importa el día.
    await db.doc('cursos/hoy').set(Object.assign({}, course, { dias: [todayNumber] }));
    await db.doc('cursos/otroDia').set(Object.assign({}, course, { dias: otherDays }));
    await db.doc('cursos/sinDias').set(Object.assign({}, course, { dias: [] }));
    // Horario por día: hoy toca a otra hora, aunque horaInicio/horaFin cubran todo el día.
    await db.doc('cursos/horaHoy').set(Object.assign({}, course, { dias: [todayNumber], horarios: { [todayNumber]: { inicio: '00:00', fin: '23:59' } } }));
    await db.doc('cursos/otraHora').set(Object.assign({}, course, { dias: [todayNumber], horarios: { [todayNumber]: notNow } }));
    await db.doc('cursos/ajeno').set(Object.assign({}, course, { dias: [todayNumber], docenteId: 'teacher2' }));
  });

  const as = (uid) => env.authenticatedContext(uid, { email: students[uid] ? students[uid].email : `${uid}@udla.edu.co` }).firestore();
  const anon = env.unauthenticatedContext().firestore();
  const ins = (uid) => `cursos/c1/inscripciones/${uid}`;

  console.log('\nUnirse al curso');
  await no('sin sesión no puede unirse', () => anon.doc(ins('stu3')).set(enrollment('stu3')));
  await no('no está en la lista y se pone como inscrito', () => as('stu3').doc(ins('stu3')).set(enrollment('stu3', { estado: 'inscrito', origen: 'lista' })));
  await no('crea la inscripción de otro', () => as('stu3').doc(ins('stu1')).set(enrollment('stu1')));
  await no('falsifica su nombre', () => as('stu3').doc(ins('stu3')).set(enrollment('stu3', { nombre: 'Otro Nombre' })));
  await no('falsifica su código', () => as('stu3').doc(ins('stu3')).set(enrollment('stu3', { codigo: '2024-0001' })));
  await no('agrega campos que no existen', () => as('stu3').doc(ins('stu3')).set(enrollment('stu3', { asistencia: 100 })));
  await no('un docente no se une como estudiante', () => as('teacher2').doc(ins('teacher2')).set({ uid: 'teacher2', nombre: 'Otro', codigo: 'DOC-2', correo: 't2@udla.edu.co', estado: 'pendiente', origen: 'solicitud', fecha: FV.serverTimestamp(), retiradoPor: null }));
  await ok('sin lista queda pendiente', () => as('stu3').doc(ins('stu3')).set(enrollment('stu3')));
  await ok('en la lista por código queda inscrito', () => as('stu1').doc(ins('stu1')).set(enrollment('stu1', { estado: 'inscrito', origen: 'lista' })));
  await ok('en la lista por correo queda inscrito', () => as('stu2').doc(ins('stu2')).set(enrollment('stu2', { estado: 'inscrito', origen: 'lista' })));
  await no('pendiente no se acepta a sí mismo', () => as('stu3').doc(ins('stu3')).update({ estado: 'inscrito' }));

  console.log('\nVolver y salir');
  await no('lo retiró el docente: no vuelve directo aunque esté en lista', () => as('stu5').doc(ins('stu5')).set(enrollment('stu5', { estado: 'inscrito', origen: 'lista' })));
  await ok('lo retiró el docente: vuelve como pendiente', () => as('stu5').doc(ins('stu5')).set(enrollment('stu5')));
  await ok('salió por su cuenta y está en lista: vuelve inscrito', () => as('stu4').doc(ins('stu4')).set(enrollment('stu4', { estado: 'inscrito', origen: 'lista' })));
  await ok('el estudiante sale del curso', () => as('stu4').doc(ins('stu4')).update({ estado: 'retirado', retiradoPor: 'estudiante' }));
  await no('no puede decir que lo retiró el docente', () => as('stu2').doc(ins('stu2')).update({ estado: 'retirado', retiradoPor: 'docente' }));
  await no('no puede sacar a otro', () => as('stu1').doc(ins('stu2')).update({ estado: 'retirado', retiradoPor: 'estudiante' }));
  await no('no puede borrar su inscripción', () => as('stu1').doc(ins('stu1')).delete());

  console.log('\nLista oficial y mis cursos');
  await ok('consulta su fila por código', () => as('stu1').doc('cursos/c1/listaOficial/2024-0001').get());
  await no('consulta la fila de otro', () => as('stu1').doc('cursos/c1/listaOficial/2024-0004').get());
  await no('lista toda la lista oficial', () => as('stu1').collection('cursos/c1/listaOficial').get());
  await ok('consulta su correo', () => as('stu2').doc('cursos/c1/listaCorreos/stu2@udla.edu.co').get());
  await no('consulta el correo de otro', () => as('stu1').doc('cursos/c1/listaCorreos/stu2@udla.edu.co').get());
  await no('escribe en la lista', () => as('stu3').doc('cursos/c1/listaOficial/2024-0003').set({ nombre: 'Caro', correo: 'x' }));
  await ok('busca sus inscripciones (collectionGroup)', () => as('stu1').collectionGroup('inscripciones').where('uid', '==', 'stu1').get());
  await no('busca las de otro', () => as('stu1').collectionGroup('inscripciones').where('uid', '==', 'stu2').get());
  await no('busca todas', () => as('stu1').collectionGroup('inscripciones').get());

  console.log('\nMarcar asistencia');
  const asis = (sid, uid) => `sesiones/${sid}/asistencias/${uid}`;
  await no('QR falso', () => as('stu1').doc(asis(SID, 'stu1')).set(attendance('stu1', { qr: 'ZZZZ' })));
  await no('sin QR', () => as('stu1').doc(asis(SID, 'stu1')).set({ estado: 'presente', hora: FV.serverTimestamp(), metodo: 'qr', deviceId: 'dev1', nombre: 'Ana Uno', codigo: '2024-0001' }));
  await no('desde otro celular', () => as('stu1').doc(asis(SID, 'stu1')).set(attendance('stu1', { deviceId: 'otro' })));
  await no('marca a otro estudiante', () => as('stu2').doc(asis(SID, 'stu1')).set(attendance('stu1')));
  await no('se hace pasar por manual', () => as('stu1').doc(asis(SID, 'stu1')).set(attendance('stu1', { metodo: 'manual', marcadoPor: 'stu1' })));
  await no('hora inventada', () => as('stu1').doc(asis(SID, 'stu1')).set(attendance('stu1', { hora: TS.fromMillis(now - 60000) })));
  await no('solicitud pendiente no marca', () => as('stu3').doc(asis(SID, 'stu3')).set(attendance('stu3')));
  await no('ya salió del curso', () => as('stu4').doc(asis(SID, 'stu4')).set(attendance('stu4')));
  await no('clase cerrada', () => as('stu1').doc(asis('cerrada', 'stu1')).set(attendance('stu1')));
  await no('se acabó el tiempo de registro', () => as('stu1').doc(asis('vencida', 'stu1')).set(attendance('stu1')));
  await no('códigos viejos: el docente dejó de publicar', () => as('stu1').doc(asis('sinDocente', 'stu1')).set(attendance('stu1')));
  await ok('con el código actual', () => as('stu1').doc(asis(SID, 'stu1')).set(attendance('stu1')));
  await ok('con el código anterior (cambió hace poco)', () => as('stu2').doc(asis(SID, 'stu2')).set(attendance('stu2', { qr: 'BBBB' })));
  await no('no se registra dos veces', () => as('stu1').doc(asis(SID, 'stu1')).set(attendance('stu1')));
  await no('no cambia su asistencia', () => as('stu1').doc(asis(SID, 'stu1')).update({ estado: 'ausente' }));
  await no('no borra su asistencia', () => as('stu1').doc(asis(SID, 'stu1')).delete());
  await ok('ve su propia asistencia', () => as('stu1').doc(asis(SID, 'stu1')).get());
  await no('no ve la de otro', () => as('stu1').doc(asis(SID, 'stu2')).get());
  await no('no lista la de todos', () => as('stu1').collection(`sesiones/${SID}/asistencias`).get());
  await no('no puede leer los códigos', () => as('stu1').doc(`sesiones/${SID}/privado/tokens`).get());
  await no('no puede leer el secreto', () => as('stu1').doc(`sesiones/${SID}/privado/secreto`).get());
  await no('no puede escribir los códigos', () => as('stu1').doc(`sesiones/${SID}/privado/tokens`).set({ qrActual: 'ZZZZ' }));
  await no('no puede cerrar la clase', () => as('stu1').doc(`sesiones/${SID}`).update({ abierta: false }));

  console.log('\nInformar al docente');
  const rep = (sid, uid) => `sesiones/${sid}/reportesFalla/${uid}`;
  await no('solicitud pendiente no reporta', () => as('stu3').doc(rep(SID, 'stu3')).set(report('stu3')));
  await no('clase cerrada', () => as('stu2').doc(rep('cerrada', 'stu2')).set(report('stu2')));
  await no('reporta por otro', () => as('stu1').doc(rep(SID, 'stu2')).set(report('stu2')));
  await ok('inscrito reporta con la clase abierta', () => as('stu2').doc(rep(SID, 'stu2')).set(report('stu2')));
  await no('solo una vez por clase', () => as('stu2').doc(rep(SID, 'stu2')).set(report('stu2')));
  await ok('el docente ve los reportes', () => as('teacher1').collection(`sesiones/${SID}/reportesFalla`).get());

  console.log('\nIniciar clase solo en un día de clase');
  const newId = (courseId) => `sesiones/${courseId}_${todayKey}`;
  await no('hoy no es día de clase del curso', () => as('teacher1').doc(newId('otroDia')).set(newSession('otroDia')));
  await no('curso sin días', () => as('teacher1').doc(newId('sinDias')).set(newSession('sinDias')));
  await no('curso de otro docente', () => as('teacher1').doc(newId('ajeno')).set(newSession('ajeno')));
  await no('un estudiante no abre clases', () => as('stu1').doc(newId('hoy')).set(newSession('hoy', { docenteId: 'stu1' })));
  await ok('hoy es día de clase', () => as('teacher1').doc(newId('hoy')).set(newSession('hoy')));
  await ok('horario por día: hoy está dentro de la hora', () => as('teacher1').doc(newId('horaHoy')).set(newSession('horaHoy')));
  await no('horario por día: hoy la clase es a otra hora', () => as('teacher1').doc(newId('otraHora')).set(newSession('otraHora')));
  await no('solo una clase por día', () => as('teacher1').doc(newId('hoy')).set(newSession('hoy', { numeroClase: 2 })));
  await ok('el estudiante escucha las clases abiertas de sus cursos', () => as('stu1').collection('sesiones').where('cursoId', 'in', ['c1', 'hoy']).where('abierta', '==', true).get());

  console.log('\nEl docente sigue funcionando');
  await ok('importa la lista', () => as('teacher1').doc('cursos/c1/listaOficial/2024-0099').set({ nombre: 'Nuevo', correo: 'n@udla.edu.co' }));
  await ok('guarda el correo de la lista', () => as('teacher1').doc('cursos/c1/listaCorreos/n@udla.edu.co').set({}));
  await no('otro docente no toca la lista', () => as('teacher2').doc('cursos/c1/listaCorreos/n@udla.edu.co').set({}));
  await ok('acepta una solicitud', () => as('teacher1').doc(ins('stu3')).update({ estado: 'inscrito', origen: 'aprobado' }));
  await ok('rechaza una solicitud', () => as('teacher1').doc(ins('stu5')).delete());
  await ok('retira a un estudiante', () => as('teacher1').doc(ins('stu2')).update({ estado: 'retirado', retiradoPor: 'docente' }));
  await ok('ve todas las asistencias', () => as('teacher1').collection(`sesiones/${SID}/asistencias`).get());
  await ok('marca asistencia manual', () => as('teacher1').doc(asis(SID, 'stu3')).set({ estado: 'presente', hora: FV.serverTimestamp(), metodo: 'manual', motivo: 'Otro', marcadoPor: 'teacher1', nombre: 'Caro Tres', codigo: '2024-0003' }));
  await ok('publica los códigos', () => as('teacher1').doc(`sesiones/${SID}/privado/tokens`).set({ qrActual: 'CCCC', qrAnterior: 'AAAA', actualizadoEn: FV.serverTimestamp() }));
  await ok('cierra la clase con presentes y ausentes', () => as('teacher1').doc(`sesiones/${SID}`).update({ abierta: false, fin: FV.serverTimestamp(), presentes: 3, ausentes: 0, manuales: 1, presentesUids: ['stu1', 'stu2', 'stu3'], ausentesUids: [] }));

  console.log('\nUsuarios (AsistlyLogin no cambia)');
  await ok('lee su perfil', () => as('stu1').doc('users/stu1').get());
  await no('no lee el perfil de otro', () => as('stu1').doc('users/stu2').get());
  await no('no cambia su rol', () => as('stu1').doc('users/stu1').update({ role: 'teacher' }));
  await no('no cambia su celular', () => as('stu1').doc('users/stu1').update({ deviceId: 'otro' }));

  await env.cleanup();
  console.log(`\nRESULTADO: ${passed} correctas, ${failed} fallidas`);
  process.exit(failed === 0 ? 0 : 1);
})().catch((e) => { console.error('ERROR:', e); process.exit(2); });
