using Microsoft.Win32;
using SkiaSharp;
using System;
using System.IO;
using Topten.RichTextKit;
using Windows.Win32;
using Windows.Win32.Foundation;
using Windows.Win32.UI.Shell;

namespace SetWindowsDesktopWallpaper
{
    class Program
    {
        static void Main(string[] args)
        {
            var desktopWallpaper = (IDesktopWallpaper)new DesktopWallpaper();

            SystemEvents.DisplaySettingsChanged += (sender, e) =>
            {
                Console.WriteLine("{0} DisplaySettingsChanged", DateTime.Now.ToString("o"));
                DumpDisplays(desktopWallpaper);
                SetWallpaper(desktopWallpaper);
            };

            DumpDisplays(desktopWallpaper);
            SetWallpaper(desktopWallpaper);

            Console.WriteLine("Waiting for system events (e.g. display resize).");
            Console.WriteLine("Press ENTER to exit.");
            Console.ReadLine();
        }

        private static void DumpDisplays(IDesktopWallpaper desktopWallpaper)
        {
            desktopWallpaper.GetBackgroundColor(out uint backgroundColorNative);
            var backgroundColor = new SKColor(backgroundColorNative);
            desktopWallpaper.GetPosition(out DESKTOP_WALLPAPER_POSITION position);
            desktopWallpaper.GetMonitorDevicePathCount(out uint monitorCount);

            Console.WriteLine("Displays Count={0}", monitorCount);
            Console.WriteLine("Wallpaper BackgroundColor={0}", backgroundColor);
            Console.WriteLine("Wallpaper Position={0}", position);

            for (uint monitorIndex = 0; monitorIndex < monitorCount; ++monitorIndex)
            {
                desktopWallpaper.GetMonitorDevicePathAt(monitorIndex, out PWSTR monitorIdNative);
                var monitorId = monitorIdNative.ToString();
                desktopWallpaper.GetMonitorRECT(monitorId, out RECT displayRect);
                desktopWallpaper.GetWallpaper(monitorId, out PWSTR wallpaperNative);
                var wallpaper = wallpaperNative.ToString();

                Console.WriteLine(
                    "Display Id={0} Position={1},{2} Size={3}x{4} Wallpaper={5}",
                    monitorId,
                    displayRect.left,
                    displayRect.top,
                    displayRect.right - displayRect.left,
                    displayRect.bottom - displayRect.top,
                    wallpaper
                );
            }
        }

        private static void SetWallpaper(IDesktopWallpaper desktopWallpaper)
        {
            var backgroundColor = SKColor.Parse("#1e1e1e");

            desktopWallpaper.SetBackgroundColor((uint)backgroundColor&0xffffff);
            desktopWallpaper.SetPosition(DESKTOP_WALLPAPER_POSITION.DWPOS_CENTER);

            desktopWallpaper.GetMonitorDevicePathCount(out uint monitorCount);

            for (uint monitorIndex = 0; monitorIndex < monitorCount; ++monitorIndex)
            {
                desktopWallpaper.GetMonitorDevicePathAt(monitorIndex, out PWSTR monitorIdNative);
                var monitorId = monitorIdNative.ToString();
                desktopWallpaper.GetMonitorRECT(monitorId, out RECT displayRect);

                SetMonitorWallpaper(desktopWallpaper, monitorIndex, monitorId, displayRect, backgroundColor);
            }
        }

        private static void SetMonitorWallpaper(IDesktopWallpaper desktopWallpaper, uint monitorIndex, string monitorId, RECT area, SKColor backgroundColor)
        {
            var rs = new RichString()
                .Alignment(TextAlignment.Center)
                .TextColor(SKColors.White)
                .FontSize(18)
                .Add($"#{monitorIndex}")
                .Paragraph().Add(monitorId)
                .Paragraph().Add($"{area.right - area.left}x{area.bottom - area.top}");

            var info = new SKImageInfo((int)rs.MeasuredWidth + 5, (int)rs.MeasuredHeight + 5);

            using (var surface = SKSurface.Create(info))
            {
                var wallpaperPath = @$"C:\desktop-wallpaper-{monitorIndex}.png";

                Console.WriteLine("Writting the display #{0} wallpaper ({1}x{2}) file at {3}...",
                    monitorIndex,
                    info.Width,
                    info.Height,
                    wallpaperPath);

                var canvas = surface.Canvas;

                canvas.Clear(backgroundColor);

                rs.Paint(canvas, new SKPoint((info.Width - rs.MeasuredWidth) / 2, (info.Height - rs.MeasuredHeight) / 2));

                using (var image = surface.Snapshot())
                using (var data = image.Encode(SKEncodedImageFormat.Png, 100))
                using (var stream = File.OpenWrite(wallpaperPath))
                {
                    data.SaveTo(stream);
                }

                desktopWallpaper.SetWallpaper(monitorId, wallpaperPath);
            }
        }
    }
}
