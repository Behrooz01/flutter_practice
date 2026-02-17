

void main() {

  Map<String, int> scores = {"Math":88,"Programming":95, "Network":89};
  //show somthing 
  print(scores["Math"]);
  //print all values 
  print(scores.values);
  //print all keys 
  print(scores.keys);
  //access elements using forEach method
  scores.forEach((key, value){

    print("$key: $value");
  }
  );

  //access elements using for each loop

  for(var entry in scores.entries){

      print(entry.key);
      print(entry.value);
  }

  

}