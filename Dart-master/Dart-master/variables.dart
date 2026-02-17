
void main() {

  //var type is inferred automatically

  var name = 'Behrooz';
  print(name);
  name = 'Bahman';
  print('------------------------');

  //Explicit 
  String name1 = 'Behrooz';
  print(name1);

  int num = 22;
  print(num);
  print('------------------------');
  //dynamic 
  dynamic variable = 'Behrooz';
  print(variable);
  variable =  22;
  print(variable);
  variable = true;
  print(variable);
  print('------------------------');
  //late initializtion 

  late String name3;

  name3 = 'Bezhan';
  print(name3);
  print('------------------------');

  //final run time constant 
  final date = DateTime.now();
  print(date);
  //date =DateTime.now(); it will cause error 

  //const compile time constant 
  const pi = 3.1412;
  //pi = 33; cause error 
  print(pi);

}