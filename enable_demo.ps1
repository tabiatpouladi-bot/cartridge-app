$ErrorActionPreference = 'Stop'
$path = Join-Path (Get-Location) 'mobile\lib\main.dart'
if (!(Test-Path $path)) { throw 'Run this script inside cartridge_app (folder containing mobile).' }
$source = [System.IO.File]::ReadAllText($path)
if ($source.Contains('class DemoData {')) { Write-Host 'Demo mode already installed.' -ForegroundColor Yellow; exit 0 }
$needle1 = "  static String token = '';"
$replace1 = "  static String token = '';`n  static bool demo = false;"
if (!$source.Contains($needle1)) { throw 'Could not locate Api token. File version mismatch.' }
$source = $source.Replace($needle1, $replace1)
$needle2 = '    final uri=Uri.parse(' 
$replace2 = "    if (demo) return DemoData.request(method, path, data);`n" + $needle2
if (!$source.Contains($needle2)) { throw 'Could not locate API request method.' }
$source = $source.Replace($needle2,$replace2)
$needle3 = "Api.token=p.getString('token')??'';if(Api.token.isNotEmpty)"
$replace3 = "Api.token=p.getString('token')??'';if(Api.token=='demo'){Api.demo=true;user={'name':'مدیر آزمایشی','role':'admin'};}else if(Api.token.isNotEmpty)"
if (!$source.Contains($needle3)) { throw 'Could not locate session restore code.' }
$source = $source.Replace($needle3,$replace3)
$needle4 = "Api.token='';setState(()=>user=null);"
$replace4 = "Api.token='';Api.demo=false;setState(()=>user=null);"
if (!$source.Contains($needle4)) { throw 'Could not locate logout code.' }
$source = $source.Replace($needle4,$replace4)
$needle5 = "const SizedBox(height:16),const Text('برای استفاده واقعی"
$replace5 = "const SizedBox(height:12),OutlinedButton.icon(onPressed:demoLogin,icon:const Icon(Icons.visibility_outlined),label:const Text('ورود آزمایشی بدون سرور'),style:OutlinedButton.styleFrom(minimumSize:const Size.fromHeight(52))),const SizedBox(height:16),const Text('برای استفاده واقعی"
if (!$source.Contains($needle5)) { throw 'Could not locate Login UI.' }
$source = $source.Replace($needle5,$replace5)
$needle6 = '  Future<void> submit() async {'
$replace6 = @'
  Future<void> demoLogin() async {
    final selection = await showDialog<String>(context:context,builder:(c)=>SimpleDialog(
      title:const Text('انتخاب نقش در نسخه آزمایشی'),
      children:const [
        SimpleDialogOption(child:Text('مدیر سیستم'),),
      ],
    ));
    if (!mounted) return;
    // All six roles are available from the following chooser.
    final role = await showModalBottomSheet<String>(context:context,showDragHandle:true,builder:(c)=>SafeArea(child:ListView(shrinkWrap:true,children:[
      const ListTile(title:Text('انتخاب کارتابل آزمایشی'),subtitle:Text('اطلاعات این بخش نمونه است')),
      for(final entry in titles.entries) ListTile(leading:const Icon(Icons.person_outline),title:Text(entry.value),onTap:()=>Navigator.pop(c,entry.key)),
    ])));
    if (role==null || !mounted) return;
    Api.demo=true;
    await widget.onLogin({'name':'کاربر آزمایشی','role':role},'demo');
  }
'@
# overwrite unnecessary preliminary dialog: only bottom sheet
$replace6 = $replace6.Substring($replace6.IndexOf('  Future<void> demoLogin() async {'))
$replace6 = $replace6.Replace(@'
    final selection = await showDialog<String>(context:context,builder:(c)=>SimpleDialog(
      title:const Text('انتخاب نقش در نسخه آزمایشی'),
      children:const [
        SimpleDialogOption(child:Text('مدیر سیستم'),),
      ],
    ));
    if (!mounted) return;
'@, '')
if (!$source.Contains($needle6)) { throw 'Could not locate Login submit method.' }
$source = $source.Replace($needle6,$replace6+"`n"+$needle6)
$demoDart = @'

// Offline demo data: this never contacts a real server and is not production storage.
class DemoData {
  static final List<Map<String,dynamic>> missions = [
    {'id':101,'model':'HP 85A','customer_name':'شرکت آریا','requested_qty':50,'collected_qty':48,'delivered_qty':0,'source_address':'تهران، خیابان ولیعصر','service_type':'charge','warranty':'عادی','status':'supplier','discrepancy_resolution':null},
    {'id':102,'model':'Canon 725','customer_name':'شرکت پارس','requested_qty':20,'collected_qty':20,'delivered_qty':0,'source_address':'تهران، میدان ونک','service_type':'repair','warranty':'شش ماهه','status':'pending','discrepancy_resolution':null},
    {'id':103,'model':'Samsung MLT-D111','customer_name':'شرکت سپهر','requested_qty':12,'collected_qty':12,'delivered_qty':12,'source_address':'تهران، سعادت آباد','service_type':'charge','warranty':'عادی','status':'completed','discrepancy_resolution':null},
  ];
  static final List<Map<String,dynamic>> batches = [
    {'id':501,'mission_id':101,'qty':30,'normal_qty':22,'warranty_qty':5,'irreparable_qty':3,'status':'financial','customer_invoice_amount':1500000,'paid_amount':0},
  ];
  static Future<dynamic> request(String method,String path,Map<String,dynamic>? data) async {
    await Future<void>.delayed(const Duration(milliseconds:120));
    if(method=='GET' && path=='/missions') return missions;
    if(method=='GET' && path=='/organizations') return [{'id':1,'name':'شرکت آریا'},{'id':2,'name':'شرکت پارس'},{'id':3,'name':'شرکت سپهر'}];
    final match=RegExp(r'^/missions/(\d+)$').firstMatch(path);
    if(method=='GET' && match!=null){
      final id=int.parse(match.group(1)!);
      final mission=missions.firstWhere((m)=>m['id']==id,orElse:()=>throw Exception('مأموریت پیدا نشد'));
      return {'mission':mission,'batches':batches.where((b)=>b['mission_id']==id).toList(),'events':[{'label':'مأموریت نمونه','actor_name':'سیستم آزمایشی','details':'فقط برای تست رابط کاربری'}]};
    }
    if(method=='POST' && path=='/missions'){
      final next=missions.map((m)=>m['id'] as int).reduce((a,b)=>a>b?a:b)+1;
      missions.insert(0,{'id':next,'model':data?['model']??'', 'customer_name':'شرکت آزمایشی','requested_qty':data?['requested_qty']??0,'collected_qty':null,'delivered_qty':0,'source_address':data?['source_address']??'','service_type':data?['service_type']??'charge','warranty':data?['warranty']??'عادی','status':'pending','discrepancy_resolution':null});
      return {'id':next};
    }
    final action=RegExp(r'^/missions/(\d+)/(approve|reject|assign|collect|complete|cancel|discrepancy-resolution|batches)$').firstMatch(path);
    if(method=='POST' && action!=null){
      final id=int.parse(action.group(1)!);final actionName=action.group(2)!;
      final mission=missions.firstWhere((m)=>m['id']==id,orElse:()=>throw Exception('مأموریت پیدا نشد'));
      switch(actionName){
        case 'approve':mission['status']='approved';break;
        case 'reject':mission['status']='rejected';break;
        case 'assign':mission['status']='pickup';break;
        case 'collect':mission['collected_qty']=data?['qty'];mission['status']='supplier';break;
        case 'complete':mission['status']='completed';break;
        case 'cancel':mission['status']='cancelled';break;
        case 'discrepancy-resolution':mission['discrepancy_resolution']=data?['reason'];break;
        case 'batches':
          final count=(data?['normal_qty'] as int? ?? 0)+(data?['warranty_qty'] as int? ?? 0)+(data?['irreparable_qty'] as int? ?? 0);
          if(count<=0)throw Exception('تعداد باید مثبت باشد');
          batches.add({'id':500+batches.length+1,'mission_id':id,'qty':count,'normal_qty':data?['normal_qty']??0,'warranty_qty':data?['warranty_qty']??0,'irreparable_qty':data?['irreparable_qty']??0,'status':'financial','customer_invoice_amount':data?['customer_invoice_amount']??0,'paid_amount':0});
          mission['status']='financial';break;
      }
      return {'ok':true};
    }
    final batchAction=RegExp(r'^/batches/(\d+)/(finance|status)$').firstMatch(path);
    if(method=='POST' && batchAction!=null){
      final b=batches.firstWhere((x)=>x['id']==int.parse(batchAction.group(1)!),orElse:()=>throw Exception('بسته پیدا نشد'));
      if(batchAction.group(2)=='finance'){
        b['customer_invoice_amount']=data?['customer_invoice_amount']??b['customer_invoice_amount'];b['paid_amount']=data?['paid_amount']??0;
        final approved=data?['supplier_invoice_approved']==true && data?['customer_invoice_issued']==true;
        final price=(b['customer_invoice_amount'] as num).toDouble();final paid=(b['paid_amount'] as num).toDouble();
        b['status']=approved&&paid>=price?'cleared':'financial';
      } else {
        final next=data?['status']?.toString()??'';
        if(next=='in_transit'&&b['status']!='cleared')throw Exception('پرداخت تأیید نشده');
        b['status']=next;
        if(next=='delivered'){
          final mission=missions.firstWhere((m)=>m['id']==b['mission_id']);
          mission['delivered_qty']=(mission['delivered_qty'] as int? ?? 0)+(b['qty'] as int);
        }
      }
      return {'ok':true};
    }
    throw Exception('این عملیات در نسخه نمایشی فعال نیست');
  }
}
'@
$source += $demoDart
[System.IO.File]::WriteAllText($path,$source,(New-Object System.Text.UTF8Encoding($false)))
Write-Host 'Demo mode added successfully to mobile/lib/main.dart' -ForegroundColor Green
Write-Host 'Now run: git add . ; git commit -m "Add offline demo login" ; git push origin main'
