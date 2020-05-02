

Please test this cases before submitting a modification.

# Basic operation tests:

## starting the client

1. Avaiable device
Expected: if that IP is up give back the prompt "> " and wait for commands
```bash
h1 python calc.py <OK IP>
> 
```

2. Not avaiable device
Expected: the IP is not reachabel, print an error regarding that
```bash
h1 python calc.py <Not ok IP>
[Any error regarding not avaiable device on IP]
```

## push

3. push nothing
Expected: an error message regarding this is not supported.
```bash
> push 
[Any error regarding this is not valid]
```

4. push numbers
Expected: response with an ID, and succesful operation
```bash
> push -1
> push 0
> push 18446744073709552000 # 2^64
```

5. push strings
Expected: response with an ID, and succesful operation
```bash
> push any text the user might want
> push "quoted text"
> push 'qouted text are easy'
```

6. push too long
Expected: an error that X is the max amount of length we allow (the X must be figured out)
```bash
> push anytextornumberthatistoolong
[Any error regarding that it is too long to store]
```

## get

7. get without ID
Expected: ID must be provided
```bash
> get
[Any error that says ID must be provided]
```

8. get with proper ID
Expected: get back the same data
```bash
> push foo
12
> get 12
12 => foo
```

9. get stateless
Expected: any number of get after each other does not modify the data
```bash
> push bar
56
> get 56
56 => bar
> get 56
56 => bar
```

10. get with inproper ID (this is optional)
Expected: no data stored with that ID
```bash
> get 0914
No associated data found
```

11. get with invalid ID
Expected: error regarding invalid ID
```bash
> get mykey
Invalid ID, cannot get the proper data.
```

## remove (if remove is implemented)

12. rm invalid ID
Expected: error regarding invalid ID
```bash
> rm topsecret
Invalid ID, cannot remove anything.
```

13. rm success
Expected: the data no longer in the databse
```bash
> push dog
43
> rm 43
> get 43
No associated data found
```

## complex cases

14. client stateless
Expected: 
```bash
$ h1 python calc.py <valid IP>
> push fox
34
> quit
$ h1 python calc.py <same valid IP>
> get 34
34 => fox
```

15. multiple entries
Expected: push multiple entries, and get back all of them
```bash
> push fox
45
> push cat
46
> push bear
47
> get 46
46 => cat
> get 47
47 => bear
> get 45
45 => fox
```





