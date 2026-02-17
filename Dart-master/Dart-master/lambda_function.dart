

//simple function 
int sum(int a, int b){
  return a+b;
}

void main() {

  //call simple function 
  var result = sum(2, 5);
  print(result);

  //lambda dunction 
  var sum1 = (int a, int b) => a + b;

  //call lambda function 
  var result2 = sum1(2,8);
  print(result2);

  var list = [1,3,2,5,4,8,7,10,9];

   list.sort((int a,int b)=> a.compareTo(b));

  print(list);
  

  //Function reuslt1 = () {
  //return a+b;
  //}


}