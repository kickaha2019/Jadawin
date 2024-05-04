package com.alofmethbin.jadawin;



import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;

public class RotateColours {
    public static void main( String [] args) {
        try {
            for (int i = 0; i < 48; i++) {
                mutate( args[0], i, args[1]);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
            System.exit(1);
        }
    }
    
    private static void flip( BufferedImage image, boolean r, boolean g, boolean b) {
        for (int i = 0; i < image.getWidth(); i++) {
            for (int j = 0; j < image.getHeight(); j++) {
                int rgb   = image.getRGB( i, j);
                int alpha = rgb & 0xFF000000;
                int red   = (rgb & 0x00FF0000) >> 16;
                int green = (rgb & 0x0000FF00) >> 8;
                int blue  = rgb & 0x000000FF;

                if ( r ) {red   = 255 - red;}
                if ( g ) {green = 255 - green;}
                if ( b ) {blue  = 255 - blue;}
                image.setRGB( i, j, alpha | (red << 16) | (green << 8) | blue);
            }
        }
    }
    
    private static void permute( BufferedImage image, int r, int g, int b) {
        for (int i = 0; i < image.getWidth(); i++) {
            for (int j = 0; j < image.getHeight(); j++) {
                int rgb   = image.getRGB( i, j);
                int alpha = rgb & 0xFF000000;
                int [] colours = new int [3];
                colours[0] = (rgb & 0x00FF0000) >> 16;
                colours[1] = (rgb & 0x0000FF00) >> 8;
                colours[2] = rgb & 0x000000FF;
                image.setRGB( i, j, alpha | (colours[r] << 16) | (colours[g] << 8) | colours[b]);
            }
        }
    }
    
    private static void mutate( String source, int version, String sink) throws IOException {
        BufferedImage image = ImageIO.read( new File( source));
        
        switch (version / 8) {
            case 1: permute( image, 0, 2, 1);
                    break;
            case 2: permute( image, 1, 0, 2);
                    break;
            case 3: permute( image, 1, 2, 0);
                    break;     
            case 4: permute( image, 2, 0, 1);
                    break;
            case 5: permute( image, 2, 1, 0);
        }
        
        switch (version % 8) {
            case  0: break;
            case  1: flip( image, true,  false, false);
                     break;
            case  2: flip( image, false, true, false);
                     break;
            case  3: flip( image, true,  true, false);
                     break;
            case  4: flip( image, false, false, true);
                     break;
            case  5: flip( image, true,  false, true);
                     break;
            case  6: flip( image, false, true, true);
                     break;
            case  7: flip( image, true,  true, true);
        }
        
        System.out.println( "... Mutated " + source + " to " + sink + version + ".png");
        ImageIO.write( image, "png", new File( sink + version + ".png"));
    }
}
