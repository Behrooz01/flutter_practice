

void main() {

  //the idea is one function will print a message "The result is:" and 
  //that function should take other function as parameter and call the 
  //function and pass two value and store the result to var result 
  //and return it. The function which i will pass that function should 
  //add the numbers and return it 

  //take function as parameter

  Function sum = (a, b) => a + b;

  var reuslt = printAndSum("The result is:", sum);

  print(reuslt);

  //return a function 

  var triple = sumAndPrintMessage("The result is:");
  print(triple(10,20));

}

Function sumAndPrintMessage(String s){

print(s);

return (a, b) => a + b;
}

int printAndSum(String message, Function sum){

  print(message);
  var result = sum(6,10);

  return result;
}