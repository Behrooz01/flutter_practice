
void main(){

  var myList = [1,2,3];
  print(myList);

  //change an item 
  myList[1] = 5;

  //Add an empty List 
  var emptyList = [];
  //add to an empty List 
  emptyList.add(55);
  //add multiple elements 
  emptyList.addAll([1,2,3,4]);//iterable

  //insert at specific location

  emptyList.insert(2, 33);
  //insert multiple values

  emptyList.insertAll(3, [100,101,102]);

  //remove specific elsements it works fine if there is not copy elements 
  emptyList.remove(100);
  print(emptyList.remove(2));
  //remove at specific location 
  emptyList.removeAt(2);
  print(emptyList.remove(2));



}

