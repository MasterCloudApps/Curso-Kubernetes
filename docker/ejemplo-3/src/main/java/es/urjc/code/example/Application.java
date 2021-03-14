package es.urjc.code.example;

import java.util.Arrays;

public class Application {
	public static void main(String[] args) {
		System.out.println("===========================");
		System.out.println("Command line application");
		System.out.println("===========================");
		
		System.out.println("=> Read arguments:");
		Arrays.stream(args)
		        .forEach(arg -> System.out.println("\t" + arg));
	}
}
