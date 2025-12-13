use gpui::*;

struct Root {}
impl Render for Root {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div().child(Stateless {})
    }
}

#[derive(IntoElement)]
struct Stateless {}
impl RenderOnce for Stateless {
    fn render(self, window: &mut Window, cx: &mut gpui::App) -> impl IntoElement {
        div().child("Stateless")
    }
}

pub fn start() {
    let app = Application::new();
    app.run(move |cx| {
        cx.spawn(async move |cx| {
            cx.open_window(WindowOptions::default(), |window, cx| cx.new(|cx| Root {}))?;
            Ok::<_, anyhow::Error>(())
        })
        .detach();
    });
}
