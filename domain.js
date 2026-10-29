export function stats(records) {
 const present=records.filter(r=>r.status==='Present').length;
 const excused=records.filter(r=>r.status==='E').length;
 const unexcused=records.filter(r=>r.status==='UE').length;
 const eligible=present+unexcused;
 const rate=eligible ? 100*present/eligible : null;
 return {present,excused,unexcused,rate,minimum:eligible?Math.max(0,Math.ceil((.70*eligible-present)/.30)):0,target:eligible?Math.max(0,Math.ceil((.75*eligible-present)/.25)):0};
}
export function csv(rows) {return '\uFEFF'+rows.map(row=>row.map(v=>'"'+String(v??'').replace(/^[=+@\-\t\r]/,'\'$&').replaceAll('"','""')+'"').join(',')).join('\r\n');}
export function xml(rows) {const esc=v=>String(v??'').replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');return '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Worksheet ss:Name="Attendance"><Table>'+rows.map(r=>'<Row>'+r.map(v=>'<Cell><Data ss:Type="String">'+esc(v)+'</Data></Cell>').join('')+'</Row>').join('')+'</Table></Worksheet></Workbook>';}
