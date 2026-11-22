import SwiftUI
import AVKit
import AVFoundation
import UniformTypeIdentifiers

enum RampEase: String, CaseIterable, Identifiable {
    case linear = "Linear", easeIn = "Ease In", easeOut = "Ease Out", smooth = "Smooth", sharp = "Sharp", step = "Step"
    var id: String { rawValue }
    func value(_ t: Double) -> Double {
        let x = min(1, max(0, t))
        switch self {
        case .linear: return x
        case .easeIn: return x * x
        case .easeOut: return 1 - (1-x)*(1-x)
        case .smooth: return x*x*(3-2*x)
        case .sharp: return x < 0.5 ? 2*x*x*x : 1 - 2*pow(1-x, 3)
        case .step: return x < 0.5 ? 0 : 1
        }
    }
}
struct SpeedKey: Identifiable {
    let id = UUID()
    var time: Double
    var speed: Double
    var ease: RampEase = .smooth
}
@MainActor
final class MotionModel: ObservableObject {
    @Published var source: URL?
    @Published var sourceDuration: Double = 0
    @Published var keys: [SpeedKey] = [SpeedKey(time: 0, speed: 1), SpeedKey(time: 1, speed: 1)]
    @Published var chosen: UUID?
    @Published var playhead: Double = 0
    @Published var busy = false
    @Published var status = "Выбери видео из файлов"
    @Published var exported: URL?
    let player = AVPlayer()

    var selectedIndex: Int? { keys.firstIndex(where: { $0.id == chosen }) }
    func speed(at fraction: Double) -> Double {
        guard let b = keys.firstIndex(where: { $0.time >= fraction }), b > 0 else {
            return (fraction <= 0 ? keys.first : keys.last)?.speed ?? 1
        }
        let a = keys[b-1], to = keys[b]
        let u = (fraction-a.time)/max(0.0001,to.time-a.time)
        return max(0.1, a.speed+(to.speed-a.speed)*a.ease.value(u))
    }
    func importVideo(_ input: URL) {
        busy = true
        status = "Загружаю видео…"
        Task {
            let access = input.startAccessingSecurityScopedResource()
            defer { if access { input.stopAccessingSecurityScopedResource() } }
            do {
                let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let name = UUID().uuidString + "." + (input.pathExtension.isEmpty ? "mov" : input.pathExtension)
                let copy = folder.appendingPathComponent(name)
                try FileManager.default.copyItem(at: input, to: copy)
                let asset = AVURLAsset(url: copy)
                let seconds = try await asset.load(.duration).seconds
                guard seconds.isFinite, seconds > 0, !(try await asset.loadTracks(withMediaType: .video)).isEmpty else {
                    throw NSError(domain: "Motion", code: 1, userInfo: [NSLocalizedDescriptionKey:"Это не видео"])
                }
                source = copy
                sourceDuration = seconds
                playhead = 0
                exported = nil
                keys = [SpeedKey(time:0,speed:1),SpeedKey(time:1,speed:1)]
                chosen = nil
                player.replaceCurrentItem(with: AVPlayerItem(url: copy))
                status = "Видео загружено. Добавь ромбики скорости."
            } catch { status = "Ошибка импорта: " + error.localizedDescription }
            busy = false
        }
    }
    func togglePlayback() {
        if player.rate > 0 { player.pause() }
        else { player.play(); player.rate = Float(speed(at: playhead)) }
    }
    func tick() {
        guard sourceDuration > 0 else { return }
        let t = player.currentTime().seconds
        if t.isFinite { playhead = min(1, max(0,t/sourceDuration)) }
        if player.rate > 0 {
            if playhead >= 0.999 { player.pause() }
            else { player.rate = Float(speed(at: playhead)) }
        }
    }
    func seek(_ fraction: Double) {
        playhead = min(1,max(0,fraction))
        player.seek(to: CMTime(seconds: playhead*sourceDuration, preferredTimescale:600), toleranceBefore:.zero,toleranceAfter:.zero)
    }
    func addKey() {
        let t = min(0.98,max(0.02,playhead))
        guard keys.count < 30, keys.allSatisfy({ abs($0.time-t) > 0.015 }) else { return }
        let k = SpeedKey(time: t, speed: speed(at:t))
        keys.append(k)
        keys.sort { $0.time < $1.time }
        chosen = k.id
    }
    func move(_ id: UUID, t: Double, speed: Double) {
        guard let i = keys.firstIndex(where:{$0.id == id}) else {return}
        let low = i==0 ? 0 : keys[i-1].time+0.015
        let high = i==keys.count-1 ? 1 : keys[i+1].time-0.015
        if i > 0 && i < keys.count-1 { keys[i].time = min(high,max(low,t)) }
        keys[i].speed = min(8,max(0.1,speed))
    }
    func deleteKey() {
        guard let i=selectedIndex, i>0, i<keys.count-1 else {return}
        keys.remove(at:i); chosen=nil
    }
    func preset(_ type: Int) {
        let presets: [[(Double, Double)]] = [
            [(0,1),(1,1)],
            [(0,1),(0.25,2.5),(0.5,0.5),(0.75,2.5),(1,1)],
            [(0,3),(0.4,0.3),(0.6,0.3),(1,3)],
            [(0,1),(0.3,4),(0.6,0.4),(1,1)],
            [(0,0.25),(1,3)]
        ]
        keys = presets[type].map { SpeedKey(time:$0.0,speed:$0.1) }
        chosen=nil
    }
    func exportMP4() {
        guard let source, !busy else {return}
        let copyKeys = keys
        let seconds = sourceDuration
        busy = true; exported = nil; status = "Экспорт MP4…"
        Task {
            do {
                let asset = AVURLAsset(url:source)
                guard let video = try await asset.loadTracks(withMediaType:.video).first else { throw NSError(domain:"Motion",code:2) }
                let audio = try await asset.loadTracks(withMediaType:.audio).first
                let comp = AVMutableComposition()
                guard let v = comp.addMutableTrack(withMediaType:.video,preferredTrackID:kCMPersistentTrackID_Invalid) else { throw NSError(domain:"Motion",code:3) }
                v.preferredTransform = try await video.load(.preferredTransform)
                let a = audio == nil ? nil : comp.addMutableTrack(withMediaType:.audio,preferredTrackID:kCMPersistentTrackID_Invalid)
                var position=CMTime.zero
                let count=min(480,max(48,Int(seconds*10)))
                let timescale: CMTimeScale=60000
                for index in 0..<count {
                    let begin=seconds*Double(index)/Double(count)
                    let end=seconds*Double(index+1)/Double(count)
                    let startTime=CMTime(seconds:begin,preferredTimescale:timescale)
                    let duration=CMTime(seconds:end-begin,preferredTimescale:timescale)
                    if duration <= .zero {continue}
                    let u=(Double(index)+0.5)/Double(count)
                    let k=max(0.1, min(8,Self.rate(keys:copyKeys, at:u)))
                    let stretched=CMTime(seconds:(end-begin)/k,preferredTimescale:timescale)
                    try v.insertTimeRange(CMTimeRange(start:startTime,duration:duration),of:video,at:position)
                    v.scaleTimeRange(CMTimeRange(start:position,duration:duration),toDuration:stretched)
                    if let audio,let a {
                        try a.insertTimeRange(CMTimeRange(start:startTime,duration:duration),of:audio,at:position)
                        a.scaleTimeRange(CMTimeRange(start:position,duration:duration),toDuration:stretched)
                    }
                    position=CMTimeAdd(position,stretched)
                }
                guard let session=AVAssetExportSession(asset:comp,presetName:AVAssetExportPresetHighestQuality) else {throw NSError(domain:"Motion",code:4)}
                let out=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".mp4")
                session.outputURL=out
                session.outputFileType=.mp4
                await withCheckedContinuation { (continuation:CheckedContinuation<Void,Never>) in
                    session.exportAsynchronously { continuation.resume() }
                }
                if session.status != .completed {throw session.error ?? NSError(domain:"Motion",code:5)}
                exported=out; status="MP4 готов. Нажми «Сохранить»."
            } catch { status="Ошибка экспорта: "+error.localizedDescription }
            busy=false
        }
    }
    nonisolated static func rate(keys: [SpeedKey],at t:Double)->Double {
        guard let b=keys.firstIndex(where:{$0.time >= t}),b>0 else {return (t<=0 ? keys.first:keys.last)?.speed ?? 1}
        let a=keys[b-1],z=keys[b]
        return a.speed+(z.speed-a.speed)*a.ease.value((t-a.time)/max(0.0001,z.time-a.time))
    }
}
struct GraphEditor: View {
    @ObservedObject var model: MotionModel
    var body: some View {
        GeometryReader { geo in
            let w=max(1,geo.size.width-24),h=max(1,geo.size.height-24)
            ZStack(alignment:.topLeading) {
                RoundedRectangle(cornerRadius:8).fill(Color.white.opacity(0.05))
                Path { p in
                    for i in 0...120 {
                        let x=Double(i)/120
                        let y=(8-model.speed(at:x))/7.9
                        let point=CGPoint(x:12+w*CGFloat(x),y:12+h*CGFloat(y))
                        if i==0 {p.move(to:point)} else {p.addLine(to:point)}
                    }
                }.stroke(.orange,style:StrokeStyle(lineWidth:2.5,lineCap:.round))
                ForEach(model.keys) { k in
                    let x=12+w*CGFloat(k.time), y=12+h*CGFloat((8-k.speed)/7.9)
                    Rectangle().fill(model.chosen == k.id ? .orange:.white)
                        .frame(width:14,height:14)
                        .rotationEffect(.degrees(45))
                        .position(x:x,y:y)
                        .onTapGesture {model.chosen=k.id;model.seek(k.time)}
                        .gesture(DragGesture(minimumDistance:1).onChanged { d in
                            model.chosen=k.id
                            model.move(k.id,t:k.time+Double(d.translation.width/w),speed:k.speed-Double(d.translation.height/h)*7.9)
                        })
                }
            }.clipped()
        }
    }
}
struct ContentView: View {
    @StateObject private var model=MotionModel()
    @State private var picking=false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:18) {
                    if model.source != nil {
                        VideoPlayer(player:model.player).aspectRatio(16/9,contentMode:.fit)
                        HStack {
                            Button {model.togglePlayback()} label:{Image(systemName:model.player.rate>0 ? "pause.fill":"play.fill")}
                            Slider(value:Binding(get:{model.playhead},set:{model.seek($0)}),in:0...1)
                            Text(String(format:"%.1fs",model.playhead*model.sourceDuration)).font(.caption.monospacedDigit())
                        }
                    } else {
                        RoundedRectangle(cornerRadius:10).fill(.white.opacity(0.06)).frame(height:185)
                            .overlay(Text("Импортируй видео").foregroundStyle(.secondary))
                    }
                    HStack {
                        Text("СКОРОСТЬ · ТАЙМ-РЕМАП").font(.caption.bold())
                        Spacer()
                        Text(String(format:"%.2fx",model.speed(at:model.playhead))).foregroundStyle(.orange)
                    }
                    GraphEditor(model:model).frame(height:210)
                    HStack {
                        Button("◇ Добавить") {model.addKey()}.disabled(model.source==nil)
                        Button("Удалить") {model.deleteKey()}.disabled(model.selectedIndex==nil)
                        Spacer()
                        Button("Сброс") {model.preset(0)}
                    }.buttonStyle(.bordered)
                    if let i=model.selectedIndex {
                        Text("Ромбик: "+String(format:"%.2fx",model.keys[i].speed))
                        Slider(value:Binding(get:{model.keys[i].speed},set:{model.move(model.keys[i].id,t:model.keys[i].time,speed:$0)}),in:0.1...8)
                        Text("График скорости").font(.caption)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(RampEase.allCases) { ease in
                                    Button(ease.rawValue) {model.keys[i].ease=ease}
                                        .tint(model.keys[i].ease==ease ? .orange:.gray)
                                }
                            }
                        }
                    }
                    Text("ПРЕСЕТЫ").font(.caption.bold())
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(0..<5,id:\.self) { i in
                                Button(["1x","Montage","Hero","Pulse","Slow → Fast"][i]) {model.preset(i)}
                            }
                        }
                    }
                    HStack {
                        Button("Выбрать видео") {picking=true}.buttonStyle(.borderedProminent)
                        Button("Экспорт MP4") {model.exportMP4()}.disabled(model.source==nil || model.busy).buttonStyle(.bordered)
                    }
                    if let exported=model.exported {
                        ShareLink(item:exported) {Text("Сохранить MP4")}.buttonStyle(.borderedProminent)
                    }
                    if model.busy {ProgressView()}
                    Text(model.status).font(.caption).foregroundStyle(.secondary)
                    Text("iOS prototype · не оригинальный Alight Motion").font(.caption2).foregroundStyle(.secondary)
                }.padding(16)
            }
            .navigationTitle("Motion iOS Lab")
            .preferredColorScheme(.dark)
            .fileImporter(isPresented:$picking,allowedContentTypes:[.movie,.video,.mpeg4Movie]) { result in
                switch result {
                case .success(let u):model.importVideo(u)
                case .failure(let e):model.status=e.localizedDescription
                }
            }
            .onReceive(Timer.publish(every:0.1,on:.main,in:.common).autoconnect()) { _ in model.tick() }
        }
    }
}
@main
struct MotionLabApp: App {
    var body: some Scene { WindowGroup {ContentView()} }
}
