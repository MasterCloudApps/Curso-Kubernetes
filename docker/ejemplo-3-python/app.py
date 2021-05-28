import sys

if __name__ == '__main__':

    print ("===========================")
    print ("Command line application")
    print ("===========================")

    print ("=> Read arguments:")

    for i, arg in enumerate(sys.argv[1:]):
        print(f"\t{arg}")
