use gpui::*;

struct Root {
    stateful: Entity<Stateful>,
}
impl Root {
    fn new(cx: &mut App) -> Self {
        Self {
            stateful: cx.new(|_| Stateful { count: 0 }),
        }
    }
}
impl Render for Root {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div().child(self.stateful.clone())
    }
}

struct Stateful {
    count: u32,
}
impl Render for Stateful {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .child(format!("Stateful: {}", self.count))
            .child(div().child("Button").on_mouse_down(
                MouseButton::Left,
                cx.listener(|this, _evt, _window, cx| {
                    this.count += 1;
                    cx.notify();
                }),
            ))
    }
}

pub fn start() {
    let app = Application::new();
    app.run(move |cx| {
        cx.spawn(async move |cx| {
            cx.open_window(WindowOptions::default(), |window, cx| {
                cx.new(|cx| Root::new(cx))
            })?;
            Ok::<_, anyhow::Error>(())
        })
        .detach();
    });
}
