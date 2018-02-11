#Thanks to wobine on github for ecc functions below.
#Link to file:
#https://github.com/wobine/blackboard101/blob/master/EllipticCurvesPart4-PrivateKeyToPublicKey.py





# Remember to use Python 2.7.6 or lower. You'll need to make changes for Python 3.

# Parameters below are recommended values obtained from standards for efficient cryptography 
# Check out secg.org for more information

# Initial Values
# Pcurve = Value of prime p, 
# N      = Number of Points in the field
# Acurve = curve parameter
# Bcurve = curve parameter
# Gx     = x-coordinate of point G
# Gy     = y-coordinate of point G
# GPoint = Generator Point

import random
import Adafruit_BBIO.UART as UART
import binascii
import serial
import datetime
import time

 


UART.setup("UART1")
ser = serial.Serial(port = "/dev/ttyO1", baudrate=9600)
ser.close()
ser.open()
if ser.isOpen():
    print "Serial is open!"

Pcurve  = 6277101735386680763835789423207666416083908700390324961279    
N       = 0xFFFFFFFFFFFFFFFFFFFFFFFE26F2FC170F69466A74DEFD8D            
Acurve  = 6277101735386680763835789423207666416083908700390324961276
Bcurve  = 1                                                            
Gx      = 602046282375688656758213480587526111916698976636884684818    
Gy      = 174050332293622031404857552280219410364023488927386650641    
GPoint  = (Gx,Gy) 

# Elliptic Curve Cryptography Operations Functions
# def modinv      : Extended Euclidean Algorithm/'division' in elliptic curves
# def ECadd       : Point Addition
# def ECdouble    : Point Doubling
# def EccMultiply : Scalar Multiplication

def modinv(a,n=Pcurve): 
    lm, hm = 1,0
    low, high = a%n,n
    while low > 1:
        ratio = high/low
        nm, new = hm-lm*ratio, high-low*ratio
        lm, low, hm, high = nm, new, lm, low
    return lm % n

def ECadd(a,b):    
    LamAdd = ((b[1]-a[1]) * modinv(b[0]-a[0],Pcurve)) % Pcurve
    x = (LamAdd*LamAdd-a[0]-b[0]) % Pcurve
    y = (LamAdd*(a[0]-x)-a[1]) % Pcurve
    return (x,y)

def ECdouble(a):    
    Lam = ((3*a[0]*a[0]+Acurve) * modinv((2*a[1]),Pcurve)) % Pcurve
    x = (Lam*Lam-2*a[0]) % Pcurve
    y = (Lam*(a[0]-x)-a[1]) % Pcurve
    return (x,y)

def EccMultiply(GenPoint,ScalarHex): 
    if ScalarHex == 0 or ScalarHex >= N: raise Exception("Invalid Scalar/Private Key")
    ScalarBin = str(bin(ScalarHex))[2:]
    Q=GenPoint
    for i in range (1, len(ScalarBin)): 
        Q=ECdouble(Q);
        #print "DUB (%s, %s)" %(Q[0], Q[1])     Uncomment print statements to see intermediate steps.
        if ScalarBin[i] == "1":
            Q=ECadd(Q,GenPoint); 
            #print "ADD (%s, %s)" %(Q[0], Q[1]) 
    return (Q)


# Complete El-Gamal Protocol 


############## for testing key change request ###################################


"""
def get_public_key():
    #y_val = int(text_file.readline(),16)
    
    text_file=open("test_keys.txt",'r')
    line =  text_file.readline()
    line = line.split(';')
    
    x_val = line[1]
    y_val = line[2] 
    
"""  
    #print int(text_file.readline(1))
     # x = Node Private Key, chosen at random.
    # Y = Node Public Key (Y = Gx).
"""
    print(x_val)
    print(y_val)
    new_x = int(x_val,16)
    new_y = int(y_val,16)
    Y = (new_x,new_y) 
    
    return Y
    
# Encryptio
# This operation will be done in the BeagleBone 


#setting up a new key
def change_key(k,Y):
    
    
    
    M = EccMultiply(GPoint, k)
          # Also, this implementation works when m and n are chosen at random.
    
    print("total M")
    print(M)
    print("this is my key")  
    print(hex(M[0]))
    f =hex(M[0])
    f_new = str(f[2:33])
   # ser.write(f_new)
    
    print f_new   #my session key
    print( len(f_new))
    
    
    R = EccMultiply(GPoint,k)           # R = message Public key 

    C = ECadd(EccMultiply(Y,k), M)

#need to send R0 R1 , C0 C1

#--------------------------------------------R0
    print("this is R0")
    print(hex(R[0]))
    R0_hex = hex(R[0])
    
    R0_str = str(R0_hex[2:50])
    print("R0 str")
    print(R0_str)
    #ser.write(hex(R[0]))
    ser.write(R0_str)
#-----------------------------------------

#--------------------------------------------R1
    print("this is R1")
    print(hex(R[1]))
    R1_hex = hex(R[1])
    
    R1_str = str(R0_hex[2:50])
    print("R1 str")
    print(R1_str)
    #ser.write(hex(R[0]))
    ser.write(R1_str)
#---------------------------------------------


#--------------------------------------------C0
    print("this is C0")
    print(hex(C[0]))
    C0_hex = hex(C[0])
    
    C0_str = str(C0_hex[2:50])
    print("C0 str")
    print(C0_str)
    #ser.write(hex(R[0]))
    ser.write(C0_str)
#---------------------------------------------
#--------------------------------------------C1
    print("this is C1")
    print(hex(C[1]))
    C1_hex = hex(C[1])
    
    C1_str = str(C1_hex[2:50])
    print("C1 str")
    print(C1_str)
    #ser.write(hex(R[0]))
    ser.write(C1_str)
#---------------------------------------------

    #ser.write(C)
    return (R,C)


def setup_new_node():
    
    Y_new = get_public_key()  #from QR code
    k=random.randint(1,N)
    
    
    
    print(k)
    return (change_key(k,Y_new))

setup_new_node()

"""




def get_public_key():
    #y_val = int(text_file.readline(),16)
    
    text_file=open("test_keys.txt",'r')
    line =  text_file.readline()
    line = line.split(';')
    
    x_val = line[1]
    y_val = line[2] 
    
    print(x_val)
    print(y_val)
    new_x = int(x_val,16)
    new_y = int(y_val,16)
    Y = (new_x,new_y) 
    return Y


def setup_and_rekey(Node_Public_Key, N): #Function returns R, C, and the 128-bit session key
    
    k = 636970447367871056343245836125454310096609638400 #message private key
    
    

    message_generator = random.randint(2000,N-1 )
    #message_generator=10
    print "This is the random message generator %s\n" %message_generator
    M = EccMultiply(GPoint, message_generator)

    f = str(hex(M[0]))[0:34]
    session_key = int(f,16)
    print("my session key")
    print(f)
    
    
   # ser.write(f) set as my session key
    print "This  the message %s\n" %message_generator

    R = EccMultiply(GPoint,k)           # R = message Public key 

    C = ECadd(EccMultiply(Node_Public_Key,k), M)
    
    
    
    
    return [R,C,f]
    

print("Rewriting Keys")

Public_key = get_public_key()

var =setup_and_rekey(Public_key,N)
print(var[2])

