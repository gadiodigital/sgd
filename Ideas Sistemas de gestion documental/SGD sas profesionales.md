Codigo dart para ejemplo sgd para inmobiliarias, estudios juridicos, etc

import \'package:flutter/material.dart\';

void main() {

runApp(const LegalCloudApp());

}

class LegalCloudApp extends StatelessWidget {

const LegalCloudApp({super.key});

\@override

Widget build(BuildContext context) {

return MaterialApp(

title: \'LegalCloud SGD\',

debugShowCheckedModeBanner: false,

theme: ThemeData(

useMaterial3: true,

colorScheme: ColorScheme.fromSeed(

seedColor: const Color(0xFF142850),

primary: const Color(0xFF142850),

secondary: const Color(0xFF27496D),

surface: Colors.white,

),

fontFamily: \'Noto Sans\',

),

home: const MainNavigationScreen(),

);

}

}

class MainNavigationScreen extends StatefulWidget {

const MainNavigationScreen({super.key});

\@override

State\<MainNavigationScreen\> createState() =\>
\_MainNavigationScreenState();

}

class \_MainNavigationScreenState extends State\<MainNavigationScreen\>
{

int \_selectedIndex = 0;

final List\<Widget\> \_screens = \[

const DashboardScreen(),

const ExplorerScreen(),

const LegalViewerScreen(),

const SignaturePortalScreen(),

const SettingsScreen(),

\];

\@override

Widget build(BuildContext context) {

final bool isDesktop = MediaQuery.of(context).size.width \> 900;

return Scaffold(

body: Row(

children: \[

if (isDesktop)

NavigationRail(

selectedIndex: \_selectedIndex,

onDestinationSelected: (int index) {

setState(() =\> \_selectedIndex = index);

},

extended: true,

leading: const Padding(

padding: EdgeInsets.symmetric(vertical: 24.0),

child: Icon(Icons.shield_outlined, size: 40, color: Color(0xFF142850)),

),

destinations: const \[

NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label:
Text(\'Dashboard\')),

NavigationRailDestination(icon: Icon(Icons.folder_copy_outlined), label:
Text(\'Expedientes\')),

NavigationRailDestination(icon: Icon(Icons.picture_as_pdf_outlined),
label: Text(\'Visor Legal\')),

NavigationRailDestination(icon: Icon(Icons.draw_outlined), label:
Text(\'Portal Firma\')),

NavigationRailDestination(icon: Icon(Icons.settings_outlined), label:
Text(\'Configuración\')),

\],

),

Expanded(child: \_screens\[\_selectedIndex\]),

\],

),

bottomNavigationBar: !isDesktop

? NavigationBar(

selectedIndex: \_selectedIndex,

onDestinationSelected: (int index) {

setState(() =\> \_selectedIndex = index);

},

destinations: const \[

NavigationDestination(icon: Icon(Icons.dashboard_outlined), label:
\'Panel\'),

NavigationDestination(icon: Icon(Icons.folder_outlined), label:
\'Archivos\'),

NavigationDestination(icon: Icon(Icons.draw_outlined), label:
\'Firma\'),

\],

)

: null,

);

}

}

// \-\-- P1: DASHBOARD \-\--

class DashboardScreen extends StatelessWidget {

const DashboardScreen({super.key});

\@override

Widget build(BuildContext context) {

return SingleChildScrollView(

padding: const EdgeInsets.all(32),

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: \[

const Text(\'Panel Operativo\', style: TextStyle(fontSize: 28,
fontWeight: FontWeight.bold)),

const Text(\'Bienvenido, Dr. Martínez - Escribanía Central\', style:
TextStyle(color: Colors.grey)),

const SizedBox(height: 32),

GridView.count(

shrinkWrap: true,

physics: const NeverScrollableScrollPhysics(),

crossAxisCount: MediaQuery.of(context).size.width \> 1200 ? 4 : 2,

crossAxisSpacing: 16,

mainAxisSpacing: 16,

// Changed childAspectRatio from 2.5 to 1.45 to provide more vertical
space for card content.

// Calculation: Minimum required height for card (CircleAvatar 40px +
vertical padding 32px + text column \~46px) is \~78px.

// If card width is 113.3 (from error constraints), then 113.3 / 78 =
\~1.45.

childAspectRatio: 1.45,

children: \[

\_buildStatCard(\'Documentos Totales\', \'1,450\', Icons.file_copy,
Colors.blue),

\_buildStatCard(\'Sellados BFA\', \'920\', Icons.hub, Colors.green),

\_buildStatCard(\'Firmas Pendientes\', \'12\', Icons.pending_actions,
Colors.orange),

\_buildStatCard(\'Alertas Legales\', \'3\', Icons.warning_amber,
Colors.red),

\],

),

const SizedBox(height: 32),

const Text(\'Actividad Reciente\', style: TextStyle(fontSize: 20,
fontWeight: FontWeight.bold)),

const SizedBox(height: 16),

\_buildActivityList(),

\],

),

);

}

Widget \_buildStatCard(String title, String val, IconData icon, Color
color) {

return Card(

child: Padding(

padding: const EdgeInsets.all(16),

child: Row(

children: \[

CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon,
color: color)),

const SizedBox(width: 16),

Flexible(

child: Column(

mainAxisAlignment: MainAxisAlignment.center,

crossAxisAlignment: CrossAxisAlignment.start,

children: \[

Text(val, style: const TextStyle(fontSize: 20, fontWeight:
FontWeight.bold), overflow: TextOverflow.ellipsis),

Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey),
overflow: TextOverflow.ellipsis),

\],

),

)

\],

),

),

);

}

Widget \_buildActivityList() {

return Column(

children: List.generate(4, (index) =\> ListTile(

leading: const Icon(Icons.history),

title: Text(\'Protocolo #\${400 + index} sellado en BFA\'),

subtitle: const Text(\'Hace 2 horas por Sec. Claudia\'),

trailing: const Icon(Icons.chevron_right),

)),

);

}

}

// \-\-- P2: EXPLORADOR \-\--

class ExplorerScreen extends StatelessWidget {

const ExplorerScreen({super.key});

\@override

Widget build(BuildContext context) {

return Scaffold(

appBar: AppBar(

title: const Text(\'Explorador de Expedientes\'),

actions: \[

Padding(

padding: const EdgeInsets.symmetric(horizontal: 16.0),

child: SizedBox(

width: 300,

child: TextField(

decoration: InputDecoration(

hintText: \'Búsqueda OCR (Contenido)\...\',

prefixIcon: const Icon(Icons.search),

border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

contentPadding: const EdgeInsets.symmetric(vertical: 0),

),

),

),

)

\],

),

body: ListView.separated(

itemCount: 10,

separatorBuilder: (\_, \_\_) =\> const Divider(height: 1),

itemBuilder: (context, index) =\> ListTile(

leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),

title: Text(\'Contrato_Alquiler_Dept_B\_\$index.pdf\'),

subtitle: Text(\'Hash: SHA256-8f973\...\${index}a\'),

trailing: Container(

padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

decoration: BoxDecoration(color: Colors.green.shade100, borderRadius:
BorderRadius.circular(8)),

child: const Text(\'Verificado BFA\', style: TextStyle(color:
Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),

),

onTap: () {},

),

),

);

}

}

// \-\-- P3: VISOR LEGAL \-\--

class LegalViewerScreen extends StatelessWidget {

const LegalViewerScreen({super.key});

\@override

Widget build(BuildContext context) {

return Row(

children: \[

Expanded(

flex: 3,

child: Container(

color: Colors.grey\[200\],

child: Center(

child: Column(

mainAxisAlignment: MainAxisAlignment.center,

children: const \[

Icon(Icons.description, size: 100, color: Colors.grey),

SizedBox(height: 16),

Text(\'Renderizador de PDF Seguro (Vista Previa)\'),

Text(\'Marcas de Agua Dinámicas Activadas\', style: TextStyle(fontSize:
10, color: Colors.red)),

\],

),

),

),

),

const VerticalDivider(width: 1),

Container(

width: 350,

padding: const EdgeInsets.all(24),

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: \[

const Text(\'Evidencia Digital\', style: TextStyle(fontSize: 18,
fontWeight: FontWeight.bold)),

const SizedBox(height: 24),

\_evidenceTile(\'Timestamp (RFC 3161)\', \'07/01/2026 14:22:01 UTC\',
Icons.timer_outlined),

\_evidenceTile(\'Blockchain BFA\', \'Tx: 0x9823f\...77d\', Icons.link),

\_evidenceTile(\'Integridad (Hash)\', \'SHA256: 7e8b9\...f01\',
Icons.fingerprint),

const Spacer(),

ElevatedButton.icon(

onPressed: () {},

icon: const Icon(Icons.verified_user_outlined),

label: const Text(\'Validar con BFA\'),

style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity,
50)),

),

\],

),

)

\],

);

}

Widget \_evidenceTile(String label, String val, IconData icon) {

return Padding(

padding: const EdgeInsets.only(bottom: 20.0),

child: Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: \[

Row(children: \[Icon(icon, size: 16), const SizedBox(width: 8),
Text(label, style: const TextStyle(fontWeight: FontWeight.bold))\]),

Text(val, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),

\],

),

);

}

}

// \-\-- P4: PORTAL DE FIRMA \-\--

class SignaturePortalScreen extends StatelessWidget {

const SignaturePortalScreen({super.key});

\@override

Widget build(BuildContext context) {

return Center(

child: ConstrainedBox(

constraints: const BoxConstraints(maxWidth: 500),

child: Card(

margin: const EdgeInsets.all(24),

child: Padding(

padding: const EdgeInsets.all(32.0),

child: Column(

mainAxisSize: MainAxisSize.min,

children: \[

const Icon(Icons.face_retouching_natural, size: 64, color:
Color(0xFF142850)),

const SizedBox(height: 16),

const Text(\'Validación de Identidad\', style: TextStyle(fontSize: 22,
fontWeight: FontWeight.bold)),

const Text(\'Siga los pasos para firmar el documento\', textAlign:
TextAlign.center),

const SizedBox(height: 32),

const ListTile(

leading: CircleAvatar(child: Text(\'1\')),

title: Text(\'Captura de DNI\'),

subtitle: Text(\'Estado: Verificado\'),

trailing: Icon(Icons.check_circle, color: Colors.green),

),

const ListTile(

leading: CircleAvatar(child: Text(\'2\')),

title: Text(\'Validación Facial (Selfie)\'),

subtitle: Text(\'Pendiente\'),

trailing: Icon(Icons.camera_alt_outlined),

),

const SizedBox(height: 32),

ElevatedButton(

onPressed: () {},

style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity,
50)),

child: const Text(\'Iniciar Captura Biométrica\'),

)

\],

),

),

),

),

);

}

}

// \-\-- P5: CONFIGURACIÓN \-\--

class SettingsScreen extends StatelessWidget {

const SettingsScreen({super.key});

\@override

Widget build(BuildContext context) {

return ListView(

padding: const EdgeInsets.all(32),

children: \[

const Text(\'Configuración del Sistema\', style: TextStyle(fontSize: 28,
fontWeight: FontWeight.bold)),

const SizedBox(height: 32),

ListTile(

title: const Text(\'Aislamiento de Tenant (PYME ID)\'),

subtitle: const Text(\'UUID: 550e8400-e29b-41d4-a716-446655440000\'),

trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () {}),

),

const Divider(),

SwitchListTile(

title: const Text(\'Sellado Automático en BFA\'),

subtitle: const Text(\'Sellar cada documento al finalizar la firma\'),

value: true,

onChanged: (v) {},

),

const Divider(),

const ListTile(

title: Text(\'Gestión de Certificados\'),

subtitle: Text(\'1 Certificado activo (ONTI Argentina)\'),

trailing: Icon(Icons.chevron_right),

),

\],

);

}

}

Pantallas ![](media/image5.png){width="6.267716535433071in"
height="3.375in"}![](media/image2.png){width="6.267716535433071in"
height="3.375in"}![](media/image3.png){width="6.267716535433071in"
height="3.375in"}![](media/image1.png){width="6.267716535433071in"
height="3.375in"}![](media/image4.png){width="6.267716535433071in"
height="3.375in"}
