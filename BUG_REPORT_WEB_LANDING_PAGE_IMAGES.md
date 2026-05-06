# Bug Report: Web Landing Page Images Not Showing

## Summary

In the web application (`tander-web`), several images on the home/landing page are not displaying correctly. Based on the provided screenshots, the image containers appear empty or show broken image indicators (alt text), suggesting a failure in the asset path resolution or missing image files.

## Investigation Findings (tander-web)

1.  **Image Usage in `HeroSection.tsx`:**
    *   `src/modules/auth/components/landing/home/HeroSection.tsx` imports `elder1` and `elder2NoBg` from `../../../../../assets/elder-1.png` and `../../../../../assets/elder-2-nobg.png` respectively.
    *   These imported variables are then used directly in `<img>` tags (e.g., `<img src={elder1} ... />`).
    *   The `src/assets` directory contains `elder-1.png` and `elder-2-nobg.png`.
    *   The corresponding alt text is "Filipino senior couple sharing stories over a laptop" and "Two Filipino friends laughing at a phone".

2.  **Image Usage in `TestimonialSpotlight.tsx`:**
    *   `src/modules/auth/components/landing/home/TestimonialSpotlight.tsx` imports `elder1` from `../../../../../assets/elder-1.png`.
    *   This `elder1` variable is used for the "Lola Nena" image (e.g., `<img src={elder1} alt="Lola Nena" ... />`).
    *   However, a specific image for "Lola Nena" (`nena.png`) exists in `public/images/stories/`. This path is also defined in `src/modules/auth/components/landing/stories/constants.ts` as `image: "/images/stories/nena.png"`.

## Root Cause

The issue stems from how static assets are being referenced and managed in the `tander-web` project:

1.  **Direct Import from `src/assets`:** When images are imported directly into a TypeScript/JavaScript file (e.g., `import elder1 from '...'`), build tools (like Vite or Webpack) typically process these imports.
    *   In a development environment, these imports are often handled to serve the images correctly.
    *   In a production build, if the build configuration is not set up to copy these `src/assets` to a publicly accessible output directory and rewrite their paths, the `src` attribute in the HTML might end up pointing to a non-existent or incorrect URL. This results in broken images.
2.  **Incorrect Image Source for "Lola Nena":** `TestimonialSpotlight.tsx` is explicitly using `elder1` (from `src/assets`) for "Lola Nena" instead of the dedicated image located at `public/images/stories/nena.png`, which is correctly defined in the `stories/constants.ts`.

## Recommended Fixes

1.  **Standardize Asset Handling:**
    *   **Option A (Recommended):** Move `elder-1.png` and `elder-2-nobg.png` from `src/assets` to the `public/images` directory (e.g., `public/images/hero/elder-1.png`). Then, update the `src` attributes in `HeroSection.tsx` to directly reference these public assets using absolute paths:
        ```typescript
        // In HeroSection.tsx
        // import elder1 from '/images/hero/elder-1.png'; // No need for import, use direct path
        // import elder2NoBg from '/images/hero/elder-2-nobg.png'; // No need for import, use direct path
        <img src="/images/hero/elder-1.png" alt="Filipino senior couple sharing stories over a laptop" ... />
        <img src="/images/hero/elder-2-nobg.png" alt="Two Filipino friends laughing at a phone" ... />
        ```
    *   **Option B:** If `src/assets` imports are intended, verify the `vite.config.ts` (or equivalent build configuration) correctly configures asset processing for production builds, ensuring these images are copied to the build output and their paths are rewritten.

2.  **Correct Image Source for "Lola Nena":**
    *   In `src/modules/auth/components/landing/home/TestimonialSpotlight.tsx`, update the `src` attribute for the "Lola Nena" image to use its correct public path from `stories/constants.ts`:
        ```typescript
        // In TestimonialSpotlight.tsx
        // import elder1 from '../../../../../assets/elder-1.png'; // Remove this import
        // Assuming you have access to STORIES constant or the image path directly
        <img
          src="/images/stories/nena.png" // Use the correct path from public/images/stories
          alt="Lola Nena"
          className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
        />
        ```

These changes should ensure that the images are correctly loaded and displayed on the web landing page.

***
**NOTE TO USER:** This report is updated within the `tander-flutter-v3` workspace and moved to the desktop directory.
***
