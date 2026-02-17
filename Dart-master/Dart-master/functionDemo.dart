

//function with no return type and no params 
void welcomeMsg(){
  print('Welocme');
}
//function with retun type no params 
String welcomeMsg1(){
  return 'Welcome';

}

//function with parameter and return type
String WelcomeWithName(String name) {
  return 'Welcome $name';
}

//optional parameter  order matters 
String wel1(String name, [name2,name3]){
  return 'Hello $name and $name2 and $name3';
}

//optional and defualt parameter  order does not matter 
String wel2(String name, {name1,name3}){
  return 'Hello $name and $name1 and $name3';
}

void main(){
  //call a function 
  welcomeMsg();

  var wel = welcomeMsg1();
  print(wel);

  var name = WelcomeWithName('Behrooz');

  print(name);

  var welcome1 = wel1('Behrooz','Bahman', 'Rashidi');
  print(welcome1);

  var welcome2 = wel2('Behrooz', name3: 'Samir');
  print(welcome2);


}