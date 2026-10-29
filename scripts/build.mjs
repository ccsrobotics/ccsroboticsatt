import {mkdir,copyFile} from 'node:fs/promises';
await mkdir('dist',{recursive:true});
for(const file of ['index.html','style.css','app.js','parent.js','calendar.js','domain.js','config.js','theme.js']) await copyFile(file,`dist/${file}`);
await copyFile('Robotics Team Attendance, Commitment, and Accountability Policy.pdf','dist/Robotics Team Attendance, Commitment, and Accountability Policy.pdf');
